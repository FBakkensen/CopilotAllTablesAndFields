controladdin "Chat Interface"
{
    RequestedHeight = 600;
    MinimumHeight = 400;
    RequestedWidth = 800;
    MinimumWidth = 600;
    VerticalStretch = true;
    HorizontalStretch = true;

    Scripts = 'src/ModernChatInterface/ChatInterface/js/ChatInterface.js';
    StyleSheets = 'src/ModernChatInterface/ChatInterface/css/ChatInterface.css';
    StartupScript = 'src/ModernChatInterface/ChatInterface/js/startup.js';

    /// <summary>
    /// Event triggered when a message is sent from the chat interface
    /// </summary>
    /// <param name="message">The message text sent by the user</param>
    event MessageSent(message: Text);

    /// <summary>
    /// Event triggered when the chat is cleared
    /// </summary>
    event ChatCleared();

    /// <summary>
    /// Event triggered when the control add-in is ready for interaction
    /// </summary>
    event AddInReady();

    /// <summary>
    /// Procedure to add a new message to the chat interface
    /// </summary>
    /// <param name="messageType">Type of message (User, Assistant, System)</param>
    /// <param name="messageText">The text content of the message</param>
    /// <param name="messageTime">Formatted time string</param>
    procedure AddMessage(messageType: Text; messageText: Text; messageTime: Text);

    /// <summary>
    /// Procedure to clear all messages from the chat interface
    /// </summary>
    procedure ClearMessages();

    /// <summary>
    /// Procedure to load chat history from JSON
    /// </summary>
    /// <param name="messagesJson">JSON array of messages to load</param>
    procedure LoadChatHistory(messagesJson: Text);

    /// <summary>
    /// Procedure to show/hide typing indicator
    /// </summary>
    /// <param name="show">Whether to show the typing indicator</param>
    procedure ShowTypingIndicator(show: Boolean);
}
