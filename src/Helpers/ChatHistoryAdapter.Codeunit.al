codeunit 51323 "Chat History Adapter"
{
    Access = Public;

    /// <summary>
    /// Generate HTML for chat display using JSON data
    /// </summary>
    /// <param name="ChatHistoryMgr">Chat History Manager instance</param>
    /// <param name="SessionId">Session to display</param>
    /// <returns>HTML content for display</returns>
    procedure GenerateHTMLFromJson(var ChatHistoryMgr: Codeunit "Chat History Manager"; SessionId: Guid): Text
    var
        JsonMessages: JsonArray;
        ChatBubbleGenerator: Codeunit "Chat Bubble HTML Generator";
    begin
        // Get messages from JSON
        JsonMessages := ChatHistoryMgr.GetSessionMessages(SessionId);

        // Generate HTML using JSON-based generator
        exit(ChatBubbleGenerator.GenerateChatHTMLFromJson(JsonMessages, SessionId));
    end;
}