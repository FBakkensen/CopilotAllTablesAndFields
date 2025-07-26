/**
 * Chat Interface Control Add-in Startup Script
 * This script initializes the chat interface when the control add-in loads
 */

// Initialize the chat interface when the DOM is ready
function initializeChatInterface() {
    console.log('Initializing Chat Interface Control Add-in...');

    // Create the main chat container
    const chatContainer = document.createElement('div');
    chatContainer.className = 'chat-container';
    chatContainer.innerHTML = `
        <div class="chat-header">
            <h2 class="chat-title">Data Explorer</h2>
            <button class="clear-btn" onclick="clearChat()">Clear Chat</button>
        </div>
        <div class="chat-messages" id="chatMessages">
            <!-- Messages will be inserted here -->
        </div>
        <div class="chat-input-container">
            <div class="input-wrapper">
                <textarea id="messageInput" placeholder="Ask me anything about Business Central..." rows="1"></textarea>
                <button class="send-btn" onclick="sendMessage()" id="sendBtn">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
                        <path d="M2,21L23,12L2,3V10L17,12L2,14V21Z"/>
                    </svg>
                </button>
            </div>
        </div>
    `;

    // Clear any existing content and add the chat container
    document.body.innerHTML = '';
    document.body.appendChild(chatContainer);

    // Set up event listeners
    setupEventListeners();

    // Notify AL that the control is ready
    if (typeof Microsoft !== 'undefined' && Microsoft.Dynamics && Microsoft.Dynamics.NAV && Microsoft.Dynamics.NAV.InvokeExtensibilityMethod) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('AddInReady', null);
    }

    console.log('Chat Interface Control Add-in initialized successfully');
}

// Set up event listeners for the chat interface
function setupEventListeners() {
    const input = document.getElementById('messageInput');
    const messagesContainer = document.getElementById('chatMessages');

    if (input) {
        // Auto-resize textarea
        input.addEventListener('input', function() {
            adjustTextareaHeight(this);
        });

        // Handle Enter key (without Shift for send)
        input.addEventListener('keydown', function(e) {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                sendMessage();
            }
        });

        // Focus on the input field
        input.focus();
    }

    // Auto-scroll to bottom when new content is added
    if (messagesContainer) {
        messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeChatInterface);
} else {
    initializeChatInterface();
}
