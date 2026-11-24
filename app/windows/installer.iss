; SPDX-License-Identifier: LicenseRef-Burumy-Proprietary
; Burumy v2 Windows installer (Inno Setup). Paths are from the repo root.
; Its own name and folder, so it sits beside the v1 test app without touching it.
[Setup]
AppId={{7B3E2A51-6C1D-4E8B-9F2A-B0B5E1A2C3D4}
AppName=Burumy v2
AppVersion=0.2.0
AppPublisher=Burumy
DefaultDirName={autopf}\Burumy v2
DefaultGroupName=Burumy v2
OutputDir=..\..\dist
OutputBaseFilename=burumy-v2-windows-setup
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=lowest
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=force

[Languages]
Name: "ko"; MessagesFile: "compiler:Languages\Korean.isl"
Name: "en"; MessagesFile: "compiler:Default.isl"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs ignoreversion

[Icons]
Name: "{group}\Burumy v2"; Filename: "{app}\burumy.exe"
Name: "{autodesktop}\Burumy v2"; Filename: "{app}\burumy.exe"

[Run]
Filename: "{app}\burumy.exe"; Description: "Burumy v2"; Flags: nowait postinstall skipifsilent
; Auto-update runs the installer quietly: open the app again afterwards.
Filename: "{app}\burumy.exe"; Flags: nowait; Check: WizardSilent
