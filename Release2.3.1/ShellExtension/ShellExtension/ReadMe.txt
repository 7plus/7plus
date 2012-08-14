========================================================================
   AKTIVE VORLAGENBIBLIOTHEK: ShellExtension-Projektübersicht
========================================================================

Der Anwendungs-Assistent hat dieses ShellExtension-Projekt als 
Ausgangspunkt zum Schreiben der DLL erstellt.

Diese Datei bietet eine Übersicht über den Inhalt der einzelnen Dateien, aus 
denen Ihr Projekt besteht.

ShellExtension.vcxproj
    Dies ist die Hauptprojektdatei für VC++-Projekte, die mit dem 
    Anwendungs-Assistenten generiert werden.
    Sie enthält Informationen zur Visual C++-Version, mit der die Datei 
    generiert wurde, sowie Informationen zu Plattformen, Konfigurationen und 
    Projektfunktionen, die mit dem Anwendungs-Assistenten ausgewählt wurden.

ShellExtension.vcxproj.filters
    Dies ist die Filterdatei für VC++-Projekte, die mithilfe eines 
    Anwendungs-Assistenten erstellt werden. 
    Sie enthält Informationen über die Zuordnung zwischen den Dateien im 
    Projekt und den Filtern. Diese Zuordnung wird in der IDE zur Darstellung 
    der Gruppierung von Dateien mit ähnlichen Erweiterungen unter einem 
    bestimmten Knoten verwendet (z. B. sind CPP-Dateien dem Filter 
    "Quelldateien" zugeordnet).

ShellExtension.idl
    Diese Datei enthält die IDL-Definitionen der Typbibliothek, der 
    Schnittstellen und Co-Klassen, die im Projekt definiert sind.
    Diese Datei wird vom MIDL-Compiler verarbeitet, um Folgendes zu generieren:
        C++-Schnittstellendefinitionen und 
             GUID-Deklarationen              (ShellExtension.h)
        GUID-Definitionen                    (ShellExtension_i.c)
        Eine Typbibliothek                   (ShellExtension.tlb)
        Marshallingcode                      (ShellExtension_p.c und 
                                                dlldata.c)

ShellExtension.h
    Diese Datei enthält die C++-Schnittstellendefinitionen und 
    GUID-Deklarationen der in ShellExtension.idl definierten Elemente. 
    Sie wird von MIDL während der Kompilierung erneut generiert.

ShellExtension.cpp
    Diese Datei enthält die Objekttabelle und die Implementierung der 
    DLL-Exporte.

ShellExtension.rc
    Dies ist eine Auflistung aller vom Programm verwendeten 
    Microsoft Windows-Ressourcen.

ShellExtension.def
    Diese Moduldefinitionsdatei stellt dem Linker die für die DLL erforderlichen
    Informationen über die Exporte bereit. Sie enthält Exporte für:
        DllGetClassObject
        DllCanUnloadNow
        DllRegisterServer
        DllUnregisterServer
        DllInstall

/////////////////////////////////////////////////////////////////////////////
Andere Standarddateien:

StdAfx.h, StdAfx.cpp
    Diese Dateien werden verwendet, um eine vorkompilierte Headerdatei
    (PCH-Datei) mit dem Namen "ShellExtension.pch und eine 
    vorkompilierte Typendatei mit dem Namen "StdAfx.obj" zu erstellen.

Resource.h
    Dies ist die Standardheaderdatei, die Ressourcen-IDs definiert.

/////////////////////////////////////////////////////////////////////////////
Proxy/Stub-DLL-Projekt und Moduldefinitionsdatei:

ShellExtensionps.vcxproj
    Dies ist die Projektdatei zum Erstellen einer Proxy/Stub-DLL.
    Die IDL-Datei im Hauptprojekt muss mindestens eine Schnittstelle 
    enthalten. Die IDL-Datei muss vor dem Erstellen der Proxy/Stub-DLL 
    kompiliert werden. In diesem Prozess werden die Dateien dlldata.c, 
    ShellExtension_i.c und ShellExtension_p.c generiert, 
    die erforderlich sind, um die Proxy/Stub-DLL zu generieren.

ShellExtensionps.vcxproj.filters
    Dies ist die Filterdatei für das Proxy-/Stubprojekt. Sie enthält 
    Informationen über die Zuordnung zwischen den Dateien im Projekt und den 
    Filtern. Diese Zuordnung wird in der IDE zur Darstellung der Gruppierung 
    von Dateien mit ähnlichen Erweiterungen unter einem bestimmten Knoten 
    verwendet (z. B. sind CPP-Dateien dem Filter "Quelldateien" zugeordnet).

ShellExtensionps.def
    Diese Moduldefinitionsdatei stellt dem Linker die für den Proxy/Stub 
    erforderlichen Informationen über die Exporte bereit.

/////////////////////////////////////////////////////////////////////////////
