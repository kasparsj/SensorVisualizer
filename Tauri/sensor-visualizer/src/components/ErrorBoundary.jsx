import React from 'react';

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { 
      hasError: false, 
      error: null, 
      errorInfo: null 
    };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true };
  }

  componentDidCatch(error, errorInfo) {
    this.setState({
      error: error,
      errorInfo: errorInfo
    });
    
    console.error('ErrorBoundary caught an error:', error, errorInfo);
  }

  handleReload = () => {
    window.location.reload();
  }

  handleReset = () => {
    this.setState({ 
      hasError: false, 
      error: null, 
      errorInfo: null 
    });
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{
          position: 'fixed',
          top: 0,
          left: 0,
          width: '100vw',
          height: '100vh',
          backgroundColor: '#1a1a1a',
          color: 'white',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          fontFamily: 'monospace',
          zIndex: 9999
        }}>
          <div style={{
            maxWidth: '600px',
            padding: '40px',
            backgroundColor: '#2a2a2a',
            border: '2px solid #ff4444',
            borderRadius: '8px',
            textAlign: 'center'
          }}>
            <h1 style={{ 
              color: '#ff4444', 
              fontSize: '24px', 
              marginBottom: '20px',
              fontWeight: 'bold'
            }}>
              Application Error
            </h1>
            
            <p style={{ 
              fontSize: '16px', 
              marginBottom: '20px',
              lineHeight: '1.5'
            }}>
              Something went wrong in the SensorVisualizer application.
            </p>

            <div style={{
              backgroundColor: '#333',
              padding: '15px',
              borderRadius: '4px',
              marginBottom: '20px',
              textAlign: 'left',
              fontSize: '12px',
              fontFamily: 'monospace',
              maxHeight: '200px',
              overflow: 'auto'
            }}>
              <strong>Error:</strong> {this.state.error && this.state.error.toString()}
              <br />
              <br />
              <strong>Stack Trace:</strong>
              <pre style={{ 
                whiteSpace: 'pre-wrap', 
                fontSize: '11px',
                margin: '5px 0 0 0'
              }}>
                {this.state.errorInfo && this.state.errorInfo.componentStack}
              </pre>
            </div>

            <div style={{ display: 'flex', gap: '10px', justifyContent: 'center' }}>
              <button
                onClick={this.handleReset}
                style={{
                  padding: '10px 20px',
                  backgroundColor: '#4444ff',
                  color: 'white',
                  border: 'none',
                  borderRadius: '4px',
                  fontSize: '14px',
                  cursor: 'pointer',
                  fontFamily: 'monospace'
                }}
              >
                Try Again
              </button>
              
              <button
                onClick={this.handleReload}
                style={{
                  padding: '10px 20px',
                  backgroundColor: '#ff4444',
                  color: 'white',
                  border: 'none',
                  borderRadius: '4px',
                  fontSize: '14px',
                  cursor: 'pointer',
                  fontFamily: 'monospace'
                }}
              >
                Reload App
              </button>
            </div>

            <p style={{ 
              fontSize: '12px', 
              marginTop: '20px',
              opacity: 0.7
            }}>
              Check the browser console for more detailed error information.
            </p>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;