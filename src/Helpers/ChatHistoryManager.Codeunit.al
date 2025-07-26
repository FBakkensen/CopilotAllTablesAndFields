codeunit 51322 "Chat History Manager"
{
    Access = Public;

    var
        ChatHistoryJson: JsonObject;

    /// <summary>
    /// Initialize a new chat session or load existing session data
    /// </summary>
    /// <param name="SessionId">The session identifier</param>
    procedure InitializeSession(SessionId: Guid)
    begin
        Clear(ChatHistoryJson);
        if not ChatHistoryJson.ReadFrom('{"sessions":{}}') then
            Error('Failed to initialize chat history JSON structure');

        EnsureSessionExists(SessionId);
    end;

    /// <summary>
    /// Add a new message to the chat history
    /// </summary>
    /// <param name="SessionId">The session identifier</param>
    /// <param name="MessageType">The type of message (User, Assistant, System)</param>
    /// <param name="MessageText">The message content</param>
    /// <param name="MessageDateTime">The timestamp of the message</param>
    procedure AddMessage(SessionId: Guid; MessageType: Text[20]; MessageText: Text; MessageDateTime: DateTime)
    var
        SessionsToken: JsonToken;
        SessionsObj: JsonObject;
        SessionToken: JsonToken;
        SessionObj: JsonObject;
        MessagesToken: JsonToken;
        MessagesArray: JsonArray;
        MessageObj: JsonObject;
        EntryNo: Integer;
    begin
        EnsureSessionExists(SessionId);

        // Get the session object
        ChatHistoryJson.Get('sessions', SessionsToken);
        SessionsObj := SessionsToken.AsObject();
        SessionsObj.Get(Format(SessionId), SessionToken);
        SessionObj := SessionToken.AsObject();
        SessionObj.Get('messages', MessagesToken);
        MessagesArray := MessagesToken.AsArray();

        // Calculate next entry number
        EntryNo := GetNextEntryNumber(MessagesArray);

        // Create new message object
        MessageObj.Add('entryNo', EntryNo);
        MessageObj.Add('sessionId', Format(SessionId));
        MessageObj.Add('messageType', MessageType);
        MessageObj.Add('messageText', MessageText);
        MessageObj.Add('messageDateTime', Format(MessageDateTime, 0, 9)); // ISO format

        // Add to messages array
        MessagesArray.Add(MessageObj);

        // Update the session object
        SessionObj.Replace('messages', MessagesArray);
        SessionsObj.Replace(Format(SessionId), SessionObj);
        ChatHistoryJson.Replace('sessions', SessionsObj);
    end;

    /// <summary>
    /// Get all messages for a specific session, sorted by datetime
    /// </summary>
    /// <param name="SessionId">The session identifier</param>
    /// <returns>JsonArray containing all messages for the session</returns>
    procedure GetSessionMessages(SessionId: Guid): JsonArray
    var
        SessionsToken: JsonToken;
        SessionsObj: JsonObject;
        SessionToken: JsonToken;
        SessionObj: JsonObject;
        MessagesToken: JsonToken;
        MessagesArray: JsonArray;
        EmptyArray: JsonArray;
    begin
        if not ChatHistoryJson.Get('sessions', SessionsToken) then
            exit(EmptyArray);

        SessionsObj := SessionsToken.AsObject();
        if not SessionsObj.Get(Format(SessionId), SessionToken) then
            exit(EmptyArray);

        SessionObj := SessionToken.AsObject();
        if not SessionObj.Get('messages', MessagesToken) then
            exit(EmptyArray);

        MessagesArray := MessagesToken.AsArray();
        exit(SortMessagesByDateTime(MessagesArray));
    end;

    /// <summary>
    /// Clear all messages for a specific session
    /// </summary>
    /// <param name="SessionId">The session identifier</param>
    procedure ClearSession(SessionId: Guid)
    var
        SessionsToken: JsonToken;
        SessionsObj: JsonObject;
        SessionToken: JsonToken;
        SessionObj: JsonObject;
        EmptyArray: JsonArray;
    begin
        if not ChatHistoryJson.Get('sessions', SessionsToken) then
            exit;

        SessionsObj := SessionsToken.AsObject();
        if not SessionsObj.Get(Format(SessionId), SessionToken) then
            exit;

        SessionObj := SessionToken.AsObject();
        SessionObj.Replace('messages', EmptyArray);
        SessionsObj.Replace(Format(SessionId), SessionObj);
        ChatHistoryJson.Replace('sessions', SessionsObj);
    end;

    /// <summary>
    /// Get the total number of messages in a session
    /// </summary>
    /// <param name="SessionId">The session identifier</param>
    /// <returns>The count of messages in the session</returns>
    procedure GetMessageCount(SessionId: Guid): Integer
    var
        MessagesArray: JsonArray;
    begin
        MessagesArray := GetSessionMessages(SessionId);
        exit(MessagesArray.Count());
    end;

    /// <summary>
    /// Get messages for a session within a specific time range
    /// </summary>
    /// <param name="SessionId">The session identifier</param>
    /// <param name="FromDateTime">Start of time range</param>
    /// <param name="ToDateTime">End of time range</param>
    /// <returns>JsonArray containing filtered messages</returns>
    procedure GetMessagesInTimeRange(SessionId: Guid; FromDateTime: DateTime; ToDateTime: DateTime): JsonArray
    var
        AllMessages: JsonArray;
        FilteredMessages: JsonArray;
        MessageToken: JsonToken;
        MessageObj: JsonObject;
        MessageDateTimeToken: JsonToken;
        MessageDateTime: DateTime;
    begin
        AllMessages := GetSessionMessages(SessionId);

        foreach MessageToken in AllMessages do begin
            MessageObj := MessageToken.AsObject();
            if MessageObj.Get('messageDateTime', MessageDateTimeToken) then begin
                if Evaluate(MessageDateTime, MessageDateTimeToken.AsValue().AsText()) then
                    if (MessageDateTime >= FromDateTime) and (MessageDateTime <= ToDateTime) then
                        FilteredMessages.Add(MessageToken);
            end;
        end;

        exit(FilteredMessages);
    end;

    /// <summary>
    /// Export the entire chat history as JSON text
    /// </summary>
    /// <returns>JSON text representation of the chat history</returns>
    procedure ExportToJson(): Text
    var
        JsonText: Text;
    begin
        ChatHistoryJson.WriteTo(JsonText);
        exit(JsonText);
    end;

    /// <summary>
    /// Import chat history from JSON text
    /// </summary>
    /// <param name="JsonText">JSON text to import</param>
    /// <returns>True if import was successful</returns>
    procedure ImportFromJson(JsonText: Text): Boolean
    begin
        Clear(ChatHistoryJson);
        exit(ChatHistoryJson.ReadFrom(JsonText));
    end;

    local procedure EnsureSessionExists(SessionId: Guid)
    var
        SessionsToken: JsonToken;
        SessionsObj: JsonObject;
        SessionObj: JsonObject;
        MessagesArray: JsonArray;
    begin
        // Get or create sessions object
        if not ChatHistoryJson.Get('sessions', SessionsToken) then begin
            Clear(SessionsObj);
            ChatHistoryJson.Add('sessions', SessionsObj);
        end else begin
            SessionsObj := SessionsToken.AsObject();
        end;

        // Check if session exists, if not create it
        if not SessionsObj.Contains(Format(SessionId)) then begin
            Clear(SessionObj);
            SessionObj.Add('sessionId', Format(SessionId));
            SessionObj.Add('messages', MessagesArray);
            SessionsObj.Add(Format(SessionId), SessionObj);
            ChatHistoryJson.Replace('sessions', SessionsObj);
        end;
    end;

    local procedure GetNextEntryNumber(MessagesArray: JsonArray): Integer
    var
        MessageToken: JsonToken;
        MessageObj: JsonObject;
        EntryNoToken: JsonToken;
        MaxEntryNo: Integer;
        CurrentEntryNo: Integer;
    begin
        MaxEntryNo := 0;

        foreach MessageToken in MessagesArray do begin
            MessageObj := MessageToken.AsObject();
            if MessageObj.Get('entryNo', EntryNoToken) then begin
                CurrentEntryNo := EntryNoToken.AsValue().AsInteger();
                if CurrentEntryNo > MaxEntryNo then
                    MaxEntryNo := CurrentEntryNo;
            end;
        end;

        exit(MaxEntryNo + 1);
    end;

    local procedure SortMessagesByDateTime(MessagesArray: JsonArray): JsonArray
    var
        SortedArray: JsonArray;
        MessagesList: List of [JsonToken];
        MessageToken: JsonToken;
        i, j : Integer;
        TempToken: JsonToken;
    begin
        // Convert array to list for sorting
        foreach MessageToken in MessagesArray do
            MessagesList.Add(MessageToken);

        // Simple bubble sort by datetime (ascending)
        for i := 1 to MessagesList.Count() - 1 do begin
            for j := 1 to MessagesList.Count() - i do begin
                if CompareMessageDateTime(MessagesList.Get(j), MessagesList.Get(j + 1)) > 0 then begin
                    TempToken := MessagesList.Get(j);
                    MessagesList.Set(j, MessagesList.Get(j + 1));
                    MessagesList.Set(j + 1, TempToken);
                end;
            end;
        end;

        // Convert back to array
        foreach MessageToken in MessagesList do
            SortedArray.Add(MessageToken);

        exit(SortedArray);
    end;

    local procedure CompareMessageDateTime(Message1: JsonToken; Message2: JsonToken): Integer
    var
        Obj1, Obj2 : JsonObject;
        DateTime1Token, DateTime2Token : JsonToken;
        DateTime1, DateTime2 : DateTime;
    begin
        Obj1 := Message1.AsObject();
        Obj2 := Message2.AsObject();

        if not Obj1.Get('messageDateTime', DateTime1Token) then
            exit(-1);
        if not Obj2.Get('messageDateTime', DateTime2Token) then
            exit(1);

        if not Evaluate(DateTime1, DateTime1Token.AsValue().AsText()) then
            exit(-1);

        if not Evaluate(DateTime2, DateTime2Token.AsValue().AsText()) then
            exit(1);

        if DateTime1 < DateTime2 then
            exit(-1)
        else begin
            if DateTime1 > DateTime2 then
                exit(1)
            else
                exit(0);
        end;
    end;
}
