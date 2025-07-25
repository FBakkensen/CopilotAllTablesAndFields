codeunit 51321 "Chat Bubble HTML Generator"
{
    Access = Internal;

    procedure GenerateChatHTML(var ChatBuffer: Record "Copilot Chat Buffer" temporary; SessionId: Guid): Text
    var
        TempChatRecord: Record "Copilot Chat Buffer" temporary;
        HTMLContent: TextBuilder;
    begin
        HTMLContent.Append(GetHTMLHeader());

        // Copy and sort chat messages by datetime
        TempChatRecord.Copy(ChatBuffer, true);
        TempChatRecord.SetRange("Session ID", SessionId);
        TempChatRecord.SetCurrentKey("Session ID", "Message DateTime");

        if TempChatRecord.FindSet() then
            repeat
                HTMLContent.Append(GenerateChatBubble(TempChatRecord));
            until TempChatRecord.Next() = 0;

        HTMLContent.Append(GetHTMLFooter());

        exit(HTMLContent.ToText());
    end;

    local procedure GenerateChatBubble(ChatRecord: Record "Copilot Chat Buffer" temporary): Text
    var
        BubbleHTML: TextBuilder;
        MessageTypeClass: Text;
        MessageTime: Text;
    begin
        MessageTypeClass := GetMessageTypeClass(ChatRecord."Message Type");
        MessageTime := Format(ChatRecord."Message DateTime", 0, '<Hours24,2>:<Minutes,2>');

        BubbleHTML.Append('<div class="message-container ' + MessageTypeClass + '">');
        BubbleHTML.Append('<div class="message-bubble">');

        // Add message type indicator for non-user messages
        if ChatRecord."Message Type" <> 'User' then
            BubbleHTML.Append('<div class="message-type">' + ChatRecord."Message Type" + '</div>');

        BubbleHTML.Append('<div class="message-content">');
        BubbleHTML.Append(FormatMessageContent(ChatRecord."Message Text"));
        BubbleHTML.Append('</div>');

        BubbleHTML.Append('<div class="message-time">' + MessageTime + '</div>');
        BubbleHTML.Append('</div>');
        BubbleHTML.Append('</div>');

        exit(BubbleHTML.ToText());
    end;

    local procedure GetMessageTypeClass(MessageType: Text[20]): Text
    begin
        case MessageType of
            'User':
                exit('user-message');
            'Assistant':
                exit('assistant-message');
            'System':
                exit('system-message');
            else
                exit('default-message');
        end;
    end;

    local procedure FormatMessageContent(MessageText: Text): Text
    var
        FormattedText: Text;
    begin
        // Basic HTML escaping and formatting
        FormattedText := MessageText;
        FormattedText := FormattedText.Replace('&', '&amp;');
        FormattedText := FormattedText.Replace('<', '&lt;');
        FormattedText := FormattedText.Replace('>', '&gt;');
        FormattedText := FormattedText.Replace('"', '&quot;');
        FormattedText := FormattedText.Replace('''', '&#39;');

        // Convert line breaks to HTML
        FormattedText := FormattedText.Replace('\n', '<br>');

        exit(FormattedText);
    end;

    local procedure GetHTMLHeader(): Text
    var
        HeaderHTML: TextBuilder;
    begin
        HeaderHTML.Append('<!DOCTYPE html>');
        HeaderHTML.Append('<html lang="en">');
        HeaderHTML.Append('<head>');
        HeaderHTML.Append('<meta charset="UTF-8">');
        HeaderHTML.Append('<meta name="viewport" content="width=device-width, initial-scale=1.0">');
        HeaderHTML.Append('<title>Chat Conversation</title>');
        HeaderHTML.Append('<style>');
        HeaderHTML.Append(GetChatBubbleCSS());
        HeaderHTML.Append('</style>');
        HeaderHTML.Append('</head>');
        HeaderHTML.Append('<body>');
        HeaderHTML.Append('<div class="chat-container">');

        exit(HeaderHTML.ToText());
    end;

    local procedure GetHTMLFooter(): Text
    var
        FooterHTML: TextBuilder;
    begin
        FooterHTML.Append('</div>'); // Close chat-container
        FooterHTML.Append('<script>');
        FooterHTML.Append('document.addEventListener("DOMContentLoaded", function() {');
        FooterHTML.Append('  var container = document.querySelector(".chat-container");');
        FooterHTML.Append('  container.scrollTop = container.scrollHeight;');
        FooterHTML.Append('});');
        FooterHTML.Append('</script>');
        FooterHTML.Append('</body>');
        FooterHTML.Append('</html>');

        exit(FooterHTML.ToText());
    end;

    local procedure GetChatBubbleCSS(): Text
    var
        CSS: TextBuilder;
    begin
        CSS.Append('* { box-sizing: border-box; margin: 0; padding: 0; }');
        CSS.Append('body { font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif; background-color: #f5f5f5; }');
        CSS.Append('.chat-container { max-width: 100%; height: 100vh; overflow-y: auto; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }');

        // Message container styles
        CSS.Append('.message-container { margin-bottom: 15px; display: flex; }');
        CSS.Append('.user-message { justify-content: flex-end; }');
        CSS.Append('.assistant-message { justify-content: flex-start; }');
        CSS.Append('.system-message { justify-content: center; }');

        // Chat bubble styles
        CSS.Append('.message-bubble { max-width: 70%; padding: 12px 16px; border-radius: 18px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); position: relative; animation: fadeIn 0.3s ease-in; }');

        // User message styling (right side, blue)
        CSS.Append('.user-message .message-bubble { background: linear-gradient(135deg, #007acc 0%, #0066aa 100%); color: white; border-bottom-right-radius: 4px; }');

        // Assistant message styling (left side, white/gray)
        CSS.Append('.assistant-message .message-bubble { background: #ffffff; color: #333; border: 1px solid #e0e0e0; border-bottom-left-radius: 4px; }');

        // System message styling (center, yellow/orange)
        CSS.Append('.system-message .message-bubble { background: linear-gradient(135deg, #ffa726 0%, #ff8f00 100%); color: white; border-radius: 12px; max-width: 50%; }');

        // Message type indicator
        CSS.Append('.message-type { font-size: 11px; font-weight: 600; opacity: 0.8; margin-bottom: 4px; text-transform: uppercase; letter-spacing: 0.5px; }');

        // Message content
        CSS.Append('.message-content { line-height: 1.4; word-wrap: break-word; }');

        // Message time
        CSS.Append('.message-time { font-size: 10px; opacity: 0.7; margin-top: 6px; text-align: right; }');
        CSS.Append('.system-message .message-time { text-align: center; }');

        // Animation
        CSS.Append('@keyframes fadeIn { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }');

        // Scrollbar styling
        CSS.Append('.chat-container::-webkit-scrollbar { width: 6px; }');
        CSS.Append('.chat-container::-webkit-scrollbar-track { background: rgba(255,255,255,0.1); }');
        CSS.Append('.chat-container::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.3); border-radius: 3px; }');
        CSS.Append('.chat-container::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,0.5); }');

        exit(CSS.ToText());
    end;
}
