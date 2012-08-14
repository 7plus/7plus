Class CVoiceCommandTrigger Extends CTrigger
{
	static Type := RegisterType(CVoiceCommandTrigger, "Voice Command Trigger")
	static Category := RegisterCategory(CVoiceCommandTrigger, "System")
	static Command := "Test"
	static __pSpeaker := ""
	static __pListener := ""
	static __pContext := ""
	static __pGrammar := ""
	static __pRules := ""
	static __pRulec := ""
	static __pState := ""

	Startup()
	{
		this.__pSpeaker				:= ComObjCreate("SAPI.SpVoice")
		this.__pListener			:= ComObjCreate("SAPI.SpInprocRecognizer")	; For not showing Windows Voice Recognition widget.
		paudioinputs				:= this.__pListener.GetAudioInputs()		; For not showing Windows Voice Recognition widget.
		this.__plistener.AudioInput	:= paudioinputs.Item(0)						; For not showing Windows Voice Recognition widget.

		ObjRelease(paudioinputs)											; Release object from memory, it is not needed anymore.

		this.__pContext := this.__pListener.CreateRecoContext()
		this.__pGrammar := this.__pContext.CreateGrammar()

		this.__pGrammar.DictationSetState(0)
		this.__pRules := this.__pGrammar.Rules()
		this.__pRulec := this.__pRules.Add("wordsRule", 0x1|0x20)
		this.__pRulec.Clear()
		this.__pState := this.__pRulec.InitialState()
	}
	
	Enable(Event)
	{
		this.__pState.AddWordTransition(ComObjParameter(13, 0), this.Command)	; ComObjParemeter(13,0) is value Null for AHK_L
		this.__pRules.Commit()
		this.__pGrammar.CmdSetRuleState("wordsRule", 1)
		this.__pRules.Commit()
		ComObjConnect(this.__pContext, "OnVoice")
		;if(this.__pSpeaker && this.__pListener && this.__pContext && this.__pGrammar && this.__pRules && this.__pRulec)
		;	this.__pSpeaker.speak("Voice recognition active")
		;else
		;{
		;	this.__pSpeaker.speak("Voice recognition initialization error!")
		;	MsgBox Voice recognition initialization error!
		;}
	}

	Disable(Event)
	{

	}

	Matches(Filter, Event)
	{
		return Filter.Command = this.Command
	}

	DisplayString()
	{
		return "Voice Command:" this.Command
	}

	GuiShow(GUI, GoToLabel = "")
	{
		this.AddControl(GUI, "Edit", "Command", "", "", "Command:", "", "", "", "", "", "")
	}
}
OnVoiceRecognition(StreamNum, StreamPos, RecogType, Result)
{
	; Grab the text we just spoke and go to that subroutine
	pphrase := Result.PhraseInfo()
	sText := pphrase.GetText()

	outputdebug Recognized voice command: %sText%
	trigger := new CVoiceCommandTrigger()
	trigger.Command := sText
	EventSystem.OnTrigger(trigger)

	ObjRelease(pphrase) ;release object from memory
	ObjRelease(sText)
}