import styled from "styled-components"

const TestStyledComponent = styled.p`
    color: red;
`

export default function Main() {
    return (
        <div>
            <h1>Main Page</h1>
            <h2>테스트 화면</h2>
            <TestStyledComponent>이것은 styled component입니다.</TestStyledComponent>
        </div>
    )
}