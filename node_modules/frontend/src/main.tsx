import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
import './index.css' // Import CSS (nếu có)

// Tìm thẻ div có id="root" trong index.html và hiển thị App lên đó
const rootElement = document.getElementById('root')

if (!rootElement) {
  throw new Error('Không tìm thấy thẻ div id="root" trong index.html')
}

createRoot(rootElement).render(
  <StrictMode>
    <App />
  </StrictMode>,
)