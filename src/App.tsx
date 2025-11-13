import React from 'react'
import './App.css'

function App() {
  const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:3000'

  return (
    <div className="App">
      <header className="App-header">
        <h1>Frontend Microservice</h1>
        <p>Welcome to your Vite + React application!</p>
        
        <div className="api-info">
          <h2>API Configuration</h2>
          <p>Current API URL: <code>{apiUrl}</code></p>
          <p>Environment: {import.meta.env.MODE}</p>
        </div>

        <div className="features">
          <h2>Features</h2>
          <ul>
            <li>✅ Vite Build System</li>
            <li>✅ React 18</li>
            <li>✅ TypeScript</li>
            <li>✅ Environment Variables</li>
            <li>✅ Docker Ready</li>
            <li>✅ CI/CD Pipeline</li>
          </ul>
        </div>
      </header>
    </div>
  )
}

export default App
