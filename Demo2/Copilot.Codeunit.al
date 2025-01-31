codeunit 70100 "Copilot Demo2"
{
    trigger OnRun()
    begin

    end;

    procedure RegisterCapability()
    var
        CopilotCapability: Codeunit "Copilot Capability";
        LearnMoreUrlTxt: Label 'https://www.bertverbeek.nl', locked = true;
    begin
        if not CopilotCapability.IsCapabilityRegistered(Enum::"Copilot Capability"::"Predict customer ledger entries") then
            CopilotCapability.RegisterCapability(Enum::"Copilot Capability"::"Predict customer ledger entries", Enum::"Copilot Availability"::Preview, LearnMoreUrlTxt);
    end;

    procedure Generate(var CopilotCustLedgerEntries: Record "Copilot Cust Ledger Entries"; var CopilotCustLedgerEntriesOpen: Record "Copilot Cust Ledger Entries"): Text
    var
        AzureOpenAI: Codeunit "Azure OpenAI";
        AOAIOperationResponse: Codeunit "AOAI Operation Response";
        AOAIChatCompletionParams: Codeunit "AOAI Chat Completion Params";
        AOAIChatMessages: Codeunit "AOAI Chat Messages";
        Result: Text;
        Prompt: text;
    begin
        SetAuthoration(AzureOpenAI);

        AOAIChatCompletionParams.SetMaxTokens(5000);
        AOAIChatCompletionParams.SetTemperature(0);

        AzureOpenAI.SetCopilotCapability(Enum::"Copilot Capability"::"Predict customer ledger entries");
        AOAIChatMessages.AddSystemMessage(GetSystemPrompt());

        Prompt := GetUserPrompt(CopilotCustLedgerEntries, CopilotCustLedgerEntriesOpen);
        AOAIChatMessages.AddUserMessage(Prompt);

        AzureOpenAI.GenerateChatCompletion(AOAIChatMessages, AOAIChatCompletionParams, AOAIOperationResponse);

        if AOAIOperationResponse.IsSuccess() then
            Result := AOAIChatMessages.GetLastMessage()
        else
            Error(AOAIOperationResponse.GetError());

        exit(Result);
    end;

    local procedure SetAuthoration(var OpenAzureAI: Codeunit "Azure OpenAI")
    var
        Endpoint: Text;
        Deployment: Text;
        [NonDebuggable]
        APIKey: Text;
    begin
        IsolatedStorage.Get('Copilot-Endpoint', Endpoint);
        IsolatedStorage.Get('Copilot-Deployment', Deployment);
        IsolatedStorage.Get('Copilot-ApiKey', ApiKey);

        OpenAzureAI.SetAuthorization(Enum::"AOAI Model Type"::"Chat Completions", Endpoint, Deployment, APIKey);
    end;

    local procedure GetSystemPrompt(): Text
    var
        SystemPrompt: TextBuilder;
    begin
        //Put this not in your app but in a keyvault
        SystemPrompt.AppendLine('The user will provide an sales invoice with an due date and a list of sales invoices that is already paid. Your task is to find the best possible date that the customer will pay.');
        SystemPrompt.AppendLine('Try to suggest several dates.');
    end;

    local procedure GetUserPrompt(var CopilotCustLedgerEntries: Record "Copilot Cust Ledger Entries"; var CopilotCustLedgerEntriesOpen: Record "Copilot Cust Ledger Entries"): Text
    var
        Newline: Char;
        UserPrompt: TextBuilder;
    begin
        if CopilotCustLedgerEntries.FindSet() then
            repeat
                UserPrompt.AppendLine('Invoice ' + CopilotCustLedgerEntries."Document No." + ' is due on ' + format(CopilotCustLedgerEntries."Due Date") + ' and paid on ' + format(CopilotCustLedgerEntries."Closed at Date") + '. ');
            until CopilotCustLedgerEntries.Next() = 0;

        UserPrompt.AppendLine('');

        UserPrompt.AppendLine('What is the payment date of Sales Invoice ' + CopilotCustLedgerEntriesOpen."Document No." + ' with an due date of ' + format(CopilotCustLedgerEntriesOpen."Due Date") + '?');
    end;

}