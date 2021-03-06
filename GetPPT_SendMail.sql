USE [ProdReports]
GO
/****** Object:  StoredProcedure [dbo].[GetPPT_SendMail]    Script Date: 05/01/2015 11:15:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER Proc [dbo].[GetPPT_SendMail] 
@RequestorAlias varchar(50) ='sea\bdoan',
@PPTFileName varchar(100) ='MMW - 95656 Oct  4 2014 .pptx',
@ControlName Varchar(100) = NULL

As
Declare @subjectmsg varchar(500),
		@bodymsg varchar(1000),
		@RequestorEmail varchar(100),
		@DestPath varchar(300),
		@OriginPath varchar(300),
		@CmdCopy varchar(300)
		
SET  @RequestorAlias = replace(@RequestorAlias,'sea\','')
SET  @RequestorEmail = @RequestorAlias + '@expedia.com'
SET  @subjectmsg = 'Your '+ @ControlName + ' File is Ready!'
SET  @DestPath = '\\chcxssatech014\c$\PPTfiles\'
IF(RIGHT(@PPTFileName,5) ='MMW -')
SET  @OriginPath ='\\chcxssatech014\c$\MMW\'
ELSE
	SET  @OriginPath ='\\chcxssatech014\c$\HVR\'
/*IF(@RequestorAlias <> 'bdoan' AND @RequestorAlias <> 'alieu' AND @RequestorAlias <> 'eskim' AND @RequestorAlias <> 'ndaudin' AND @RequestorAlias <> 'ntorrent' AND @RequestorAlias <> 'stilsto')
	BEGIN*/
		SET @bodymsg = 
		'Dear ' + @RequestorAlias + ': '+ CHAR(10) + CHAR(13) + ' <br><br>

		Please click on this ' + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(13) +
		'<a href="\\CHCXSSATECH014\PPTfiles\'+REPLACE(@PPTFileName,'xlsx','pptx') + '"> Link </A>' + CHAR(10) + CHAR(13) + ' to download your powerpoint file! <br> <br>'

		+ CHAR(10) + CHAR(13) + '
		Please note the link will be expired after 48 hours from when it is sent! <br> <br>'

		+ CHAR(10) + CHAR(13) + '

		Thank you for the opportunity of serving you! <br> <br>'

		+ CHAR(10) + CHAR(13) + '

		-The SSA BI Dev Team' + CHAR(10) + CHAR(13)
	/*END
ELSE
		BEGIN
		SET @bodymsg = 
		'Dear ' + @RequestorAlias + ': '+ CHAR(10) + CHAR(13) + ' <br><br>

		     Please follow the below links to download your files: <br><br>' 
		     
		     + CHAR(10) + CHAR(13) + CHAR(10) + CHAR(13) +
		'	1)<a href="\\CHCXSSATECH014\PPTfiles\'+ Replace(@PPTFileName,'xlsx','pptx') + '"> Powerpoint Deck </A>' + CHAR(10) + CHAR(13) + '<br> <br>'

		+ CHAR(10) + CHAR(13) + 
		
		'	2)<a href="\\CHCXSSATECH014\PPTfiles\'+ @PPTFileName + '"> Excel Data File </A>' + CHAR(10) + CHAR(13) + '<br> <br>'

		+ CHAR(10) + CHAR(13) + '
		Please note the links will be expired after 72 hours from when it is sent! <br> <br>'

		+ CHAR(10) + CHAR(13) + '

		Thank you for the opportunity of serving you! <br> <br>'

		+ CHAR(10) + CHAR(13) + '

		-The SSA BI Dev Team' + CHAR(10) + CHAR(13)
	END*/
	

EXEC Master.[dbo].[Send_CDOSysMailGeoMappings] 
@From = 'ssabidev@expedia.com',
@To = @RequestorEmail,
@BCC = 'bdoan@expedia.com',
@subject =@subjectmsg, 
@body = @bodymsg
