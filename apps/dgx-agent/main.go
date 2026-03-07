package main

import (
	"encoding/json"
	"log"
	"net/http"
	"sync"
)

type AccountRequest struct {
	RequestID string `json:"request_id"`
	Username  string `json:"username"`
}

type AccountResponse struct {
	RequestID string `json:"request_id"`
	Status    string `json:"status"`
	Action    string `json:"action"`
	Username  string `json:"username"`
}

var (
	requestStore = make(map[string]AccountResponse)
	mu           sync.Mutex
)

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)

	_ = json.NewEncoder(w).Encode(map[string]string{
		"status": "ok",
	})
}

func handleAccountAction(action string, w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
		return
	}

	var req AccountRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid json body", http.StatusBadRequest)
		return
	}

	if req.RequestID == "" {
		http.Error(w, "request_id is required", http.StatusBadRequest)
		return
	}

	if req.Username == "" {
		http.Error(w, "username is required", http.StatusBadRequest)
		return
	}

	mu.Lock()
	defer mu.Unlock()

	// 같은 request_id가 이미 있으면 예전 결과 그대로 반환함
	if saved, exists := requestStore[req.RequestID]; exists {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(saved)
		return
	}

	// 처음 들어온 request_id면 새 결과 생성함
	resp := AccountResponse{
		RequestID: req.RequestID,
		Status:    "success",
		Action:    action,
		Username:  req.Username,
	}

	requestStore[req.RequestID] = resp

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(resp)
}

func createHandler(w http.ResponseWriter, r *http.Request) {
	handleAccountAction("create", w, r)
}

func disableHandler(w http.ResponseWriter, r *http.Request) {
	handleAccountAction("disable", w, r)
}

func archiveHandler(w http.ResponseWriter, r *http.Request) {
	handleAccountAction("archive", w, r)
}

func purgeHandler(w http.ResponseWriter, r *http.Request) {
	handleAccountAction("purge", w, r)
}

func main() {
	http.HandleFunc("/health", healthHandler)
	http.HandleFunc("/accounts/create", createHandler)
	http.HandleFunc("/accounts/disable", disableHandler)
	http.HandleFunc("/accounts/archive", archiveHandler)
	http.HandleFunc("/accounts/purge", purgeHandler)

	log.Println("Mock DGX Agent listening on :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}