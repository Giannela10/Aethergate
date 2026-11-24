[Setup]
AppId=DuocGames.NEXO
AppName=DuocGames
AppVersion=8.0
DefaultDirName={autopf}\DuocGames
DefaultGroupName=DuocGames
DisableProgramGroupPage=yes
DisableWelcomePage=no
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
UninstallDisplayIcon={app}\DuocGames.exe
SetupIconFile=DuocGames.ico
OutputDir=..\Instalar DuocGames
OutputBaseFilename=DuocGames_Setup
Compression=lzma2/fast
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Files]
Source: "..\dist\windows\DuocGames.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\dist\windows\DuocGames.pck"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\DuocGames"; Filename: "{app}\DuocGames.exe"; WorkingDir: "{app}"
Name: "{autodesktop}\DuocGames"; Filename: "{app}\DuocGames.exe"; WorkingDir: "{app}"

[Run]
Filename: "{app}\DuocGames.exe"; WorkingDir: "{app}"; Description: "Ejecutar DuocGames"; Flags: nowait postinstall skipifsilent
