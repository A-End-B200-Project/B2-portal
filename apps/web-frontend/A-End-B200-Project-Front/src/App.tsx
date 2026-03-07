import { Route, Routes } from 'react-router-dom'
import './App.css'
import Main from './pages/Main'

function App() {

  return (
    <>
    <Routes>
      <Route path="/" element={<Main></Main> } />
      <Route path="/test" element={<div>Routes 테스트 페이지</div> } />
    </Routes>
    </>
  )
}

export default App
