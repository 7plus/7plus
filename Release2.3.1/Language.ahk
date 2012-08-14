/*
This file contains language-related code
*/
Class CLanguages
{
	Languages := {}
	__New()
	{
		this.LoadLanguages()
	}
	LoadLanguages()
	{
		this.Languages.en := new CLanguage("en", "English", "")
		this.Languages.fr := new CLanguage("fr", "Francais", "fr_")
	}
	GetCurrentLanguage()
	{
		return this.Languages[Settings.General.Language]
	}
}
Class CLanguage
{
	__New(ShortName, FullName, WikiPrefix)
	{
		this.ShortName := ShortName
		this.FullName := FullName
		this.WikiPrefix := WikiPrefix
		this.Strings := Object()
	}
	LoadLocalizedStrings() ;Empty for now until localization kicks in
	{
	
	}
}
OpenWikiPage(Page, SkipTranslation = false)
{
	global Languages
	run % "http://code.google.com/p/7plus/wiki/" (SkipTranslation ? "" : Languages.GetCurrentLanguage().WikiPrefix) Page, UseErrorLevel
}