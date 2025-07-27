codeunit 51324 "Chat History Demo"
{
    Access = Internal;

    /// <summary>
    /// Demonstrate the new JSON-based chat history system
    /// </summary>
    procedure DemonstrateChatHistory()
    var
        ChatHistoryMgr: Codeunit "Chat History Manager";
        ChatHistoryAdapter: Codeunit "Chat History Adapter";
        SessionId: Guid;
        JsonMessages: JsonArray;
        HTMLContent: Text;
        JsonExport: Text;
    begin
        // Initialize a new session
        SessionId := CreateGuid();
        ChatHistoryMgr.InitializeSession(SessionId);

        // Add some sample messages
        ChatHistoryMgr.AddMessage(SessionId, 'System', 'Chat session started', CurrentDateTime);
        ChatHistoryMgr.AddMessage(SessionId, 'User', 'What tables are available in Business Central?', CurrentDateTime);
        ChatHistoryMgr.AddMessage(SessionId, 'Assistant', 'Business Central has many tables including Customer, Item, Vendor, etc.', CurrentDateTime);
        ChatHistoryMgr.AddMessage(SessionId, 'User', 'Tell me about the Customer table fields', CurrentDateTime);

        // Demonstrate retrieving messages
        JsonMessages := ChatHistoryMgr.GetSessionMessages(SessionId);
        Message('Session has ' + Format(JsonMessages.Count()) + ' messages');

        // Demonstrate HTML generation
        HTMLContent := ChatHistoryAdapter.GenerateHTMLFromJson(ChatHistoryMgr, SessionId);
        Message('Generated HTML content length: ' + Format(StrLen(HTMLContent)));

        // Demonstrate JSON export/import
        JsonExport := ChatHistoryMgr.ExportToJson();
        Message('Exported JSON length: ' + Format(StrLen(JsonExport)));

        // Clear session
        ChatHistoryMgr.ClearSession(SessionId);
        Message('Session cleared. Message count: ' + Format(ChatHistoryMgr.GetMessageCount(SessionId)));
    end;
}
