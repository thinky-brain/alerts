#!/usr/bin/perl
# NOTE: In Unix or Linux OS, change /usr/bin/perl to the full path of the perl executable.
#
# SCCGI04.PL
#
# Survey Crafter Professional Perl script to process CGI input
# http://www.surveycrafter.com
# $Id: sccgi04.pl,v 4.6.0.10 2010/03/23 11:37:00  $
#
# Copyright(c) 2000-2010 Survey Crafter, Inc. All Rights Reserved
#
# Portions Copyright(c) 1996-2000 Monitor Company. All Rights Reserved
# Portions Copyright(c) 1996 Steven E. Brenner

	# --------------------------------------
	# Operating System Specific Instructions
	# --------------------------------------

	# Set the following value to 'No' for Win9x / Millenium or configurations where flock is not supported
	$E_useFlock = 'Yes' ;				# Yes means enable file locking (Unix/WinNT/Win2K only)

	# ----------------------------------------------------------------
	# Define global scalars and associative arrays used in the routine
	# ----------------------------------------------------------------

	$kVersion = "4.6.0.10" ;			# Script version constant

	# Initialize page source constants
	$kSurveyPage = 'survey' ;			# Called by original survey page
	$kDirect = 'direct' ;				# Called directly from URL
	$kScriptPage = 'script' ;			# Called by script-generated survey page

	# Initialize rule constants
	$kLoading = 'loading' ;				# Running rules when loading a page
	$kSaving = 'saving' ;				# Running rules when saving responses

	# Initialize code constants
	$kCodePercent = '%25' ;				# % code equivalent
	$kCodeAmpersand = '%26' ;			# & code equivalent
	$kCodeEquals = '%3D' ;				# = code equivalent
	$kCodeSemicolon = '%3B' ;			# ; code equivalent
	$kCodeSpace = '%20' ;				#   code equivalent
	$kCodeDblQuote = '%22' ;			# " code equivalent
	$kCodeHash = '%23' ;					# # code equivalent
	$kCodePlus = '%2B' ;					# + code equivalent
	$kCodeFwdSlash = '%2F' ;			# / code equivalent
	$kCodeColon = '%3A' ;				# : code equivalent
	$kCodeLT = '%3C' ;					# < code equivalent
	$kCodeGT = '%3E' ;					# > code equivalent
	$kCodeQstn = '%3F' ;					# ? code equivalent
	$kCodeNL = '%0A' ;					# \n code equivalent
	$kCodeCR = '%0D' ;					# \r code equivalent
	$kCodeComma = '%2C' ;				# , code equivalent

	# Initialize error message constants
	$kErrMsgDelimiter = '!~!';			# Error and warning message delimiter

	# Initialize global field constants
	$kg_GetRecVarValues = 'SYS_GetRecVarValues' ; # Global field saves the result of getting the record
	$kg_BookmarkOnBack = 'SYS_BookmarkOnBack' ; # Global field determines if bookmark on back button
	$kg_ApplyRule = 'SYS_ApplyRule' ; # Global field determines if rules are applied

	# Initialize index file constants
	$kIndexFileVersion = 1 ;			# Index file version constant
	$kIndexFileSeparator = "|+" ;		# Index file separator constant

	# Initialize required parameters
	$E_version = 4 ;						# Script version

	# File locking parameters
	$E_flockFileExt = '\'.lck\'' ;	# Flock locking filename extension
	$E_fexistFileExt = '\'.lck.tmp\'' ;	# File existence locking filename extension
	$E_fexistTimeOutThreshold = 30 ;	# File existence locking time-out threshold in seconds
	$E_fexistWaitToTryAgain = 0 ;		# File existence locking wait-to-try-again in seconds

	# Id file parameters
	$E_idFileExt = '\'.id\'' ;			# Id file filename extension

	# Index file parameters
	$E_useIndexFile = 'No' ;			# Use an index file?
	$E_indexFileExt = '\'.idx\'' ;	# Index file filename extension
	$E_indexFileMinBufSize = 50 ;		# Minimum index file buffer size
	$E_indexFileMaxBufSize = 1000 ;	# Maximum index file buffer size

	# Initialize optional parameters
	$E_applyRule = 'Yes' ;				# Run the rules?
	$E_allowNoResponse = 'Yes' ;		# Allow no response?
	$E_clearOnDiffRecord = 'Yes' ;	# Clear the forward arrays if loading a different record?
	$E_decimalPoint = '.' ;				# Default decimal point character
	$E_writeOnNext = 'No' ;				# Write data on next?

	$E_useRecID = 'Yes' ;				# Use special id column?
	$E_recIDVar = '_#' ;					# Special id column variable name
	$E_useRecCnt = 'Yes' ;				# Use special count column?
	$E_recCntVar = '_$' ;				# Special count column variable name
	$E_useMulRec = 'No' ;				# Get all matching records?
	$E_maxMulRecs = 20 ;					# Maximum matching records
	$E_matchEmpty = 'No' ;				# Match empty values?
	$E_alwaysGetRec = 'No' ;			# Always get records?
	$E_getRecCnt = 'No' ;				# Get the record count?
	$E_checkTimeStamp = 'No' ;			# Check the time stamp?
	$E_timeStamp = '' ;					# Page time stamp
	$E_bookmarking = 'Yes' ;			# Bookmarking?
	$E_allowPageSkipping = 'No' ;		# Allow page skipping?
	$E_getRecIDDirect = 'Yes' ;		# Okay to use the record id to get records when called directly from URL?

	$bDoNext = 'No' ;						# Go to the next page?
	$bGoBack = 'No' ;						# Go back?
	$bIgnoreWarnings = 'No' ;			# Ignore warnings?
	$bReload = 'No' ;						# Reload the page?
	$bGoToBookmark = 'No' ;				# Go to bookmarked page?

	$bReloadingPage = 'No' ;			# Reloading page?
	$bQueryChanged = 'No' ;				# Query changed?
	$bCreateDataFile = 'No' ;			# Automatically create the data file?

	$E_dataSrc = $kDirect ;				# Caller source (direct or survey)

	$E_varList = '' ;						# List of variables
	$E_varDefVal = '' ;					# List of default values
	$E_varFwdVal = '' ;					# List of forwarded values
	$E_dataFileName = '' ;				# Full path of the data file
	$E_dataFileAddExt = '' ;			# Additional data file path extention

	$E_file = '' ;							# Full path of the survey page to load
	$E_reloadFileName = '' ;			# Full path of the calling survey page
	$E_reloadFileField = '' ;			# Field name of calling survey page
	$E_nextFileName = '' ;				# Full path of the next survey page
	$E_nextFileField = '' ;				# Field name of next survey page
	@E_backFileName = () ;				# Full paths of previous survey pages
	$E_bookmarkFileName = '' ;			# Full path of the bookmarked survey page
	$E_bookmarkFileField = '' ;		# Field name of the bookmarked survey page
	@E_bookmarkOnBack = () ;			# Bookmark on back values of previous survey pages

	$E_cgiURL = '' ;						# CGI URL (3.0 only)
	$E_aspURL = '' ;						# ASP URL (3.0 only)
	$E_scriptURL = '' ;					# Script URL

	$E_sendMailUseEnv = 'Yes' ;								# Get sendmail program command from environment variable?
	$E_sendMailEnvPrefix = 'SCPRO_' ;						# Sendmail environment variable name prefix

	$E_sendMail = '\'No\'' ;									# Send e-mail notification?
	$E_sendMailEnv = '\'SENDMAIL\'' ;						# Rest of sendmail environment variable name
	$E_sendMailProg = '' ;										# Sendmail program command
	$E_sendMailProgTo = '"To: $smTo\n"' ;					# Sendmail program To:
	$E_sendMailProgCC = '"Cc: $smCC\n"' ;					# Sendmail program Cc:
	$E_sendMailProgBCC = '"Bcc: $smBCC\n"' ;				# Sendmail program Bcc:
	$E_sendMailProgFrom = '"From: $smFrom\n"' ;			# Sendmail program From:
	$E_sendMailProgDate = '"Date: $smDate\n"' ;			# Sendmail program Date:
	$E_sendMailProgSubj = '"Subject: $smSubject\n"' ;	# Sendmail program Subject:
	$E_sendMailProgBody = '"\n$smBody\n"' ;				# Sendmail program body:
	$E_sendMailMsgTo = '' ;										# Sendmail message To:
	$E_sendMailMsgCC = '' ;										# Sendmail message Cc:
	$E_sendMailMsgBCC = '' ;									# Sendmail message Bcc:
	$E_sendMailMsgFrom = '' ;									# Sendmail message From:
	$E_sendMailMsgDate = '' ;									# Sendmail message Date:
	$E_sendMailMsgSubj = '' ;									# Sendmail message Subject:
	$E_sendMailMsgBody = '' ;									# Sendmail message body:
	$E_sendMailMsgBodyFile = '' ;								# Sendmail message body from file:
	$E_sendMailErrorFatal = '\'Yes\'' ;						# Sendmail errors are fatal?

	$E_msgRuleNotNum = 'Your response \"$value\" is not a number. Please enter a number.' ;
	$E_msgRuleMinNum = 'The number \"$value\" you entered is less than the expected minimum of $min.' ;
	$E_msgRuleMaxNum = 'The number \"$value\" you entered is greater than the expected maximum of $max.' ;
	$E_msgRulePosNum = 'The number \"$value\" you entered is not a positive integer.' ;
	$E_msgRuleRnkOne = 'The rankings you entered do not start at 1.' ;
	$E_msgRuleRnkGap = 'The rankings you entered are not consecutive.' ;
	$E_msgRuleCsmSum = 'The values you entered total $sum instead of the expected $sumOfAll.' ;
	$E_msgRuleReqRsp = 'An answer is required. Please answer the question.' ;
	$E_msgRuleMisRsp = 'No answer was given. Please answer the question.' ;
	$E_msgRuleMinReq = 'Please answer $minDefVars or more of the following $numOfVars questions.' ;
	$E_msgRuleMaxReq = 'Please answer no more than $maxDefVars of the following $numOfVars questions.' ;
	$E_msgRuleMinMaxReq = 'Please answer between $minDefVars and $maxDefVars of the following $numOfVars questions.' ;
	$E_msgRuleExaReq = 'Please answer $minDefVars of the following $numOfVars questions.' ;
	$E_msgRuleAllReq = 'Please answer the question(s).' ;		# For compatibility with previous versions
	$E_msgRuleMinMis = 'Please answer $minDefVars or more of the following $numOfVars questions.' ;
	$E_msgRuleMaxMis = 'Please answer no more than $maxDefVars of the following $numOfVars questions.' ;
	$E_msgRuleMinMaxMis = 'Please answer between $minDefVars and $maxDefVars of the following $numOfVars questions.' ;
	$E_msgRuleExaMis = 'Please answer $minDefVars of the following $numOfVars questions.' ;
	$E_msgRuleAllMis = 'Please answer the question(s).' ;		# For compatibility with previous versions
	$E_msgSysCantLock = 'The system may be busy. Please try again. If this message appears again, please contact this site\'s webmaster.' ;
	$E_msgRuleMinYesReq = 'Please choose $minYesVars or more items.' ;
	$E_msgRuleMinMaxYesReq = 'Please choose between $minYesVars and $maxYesVars items.' ;
	$E_msgRuleMaxYesReq = 'Please choose no more than $maxYesVars item(s).' ;
	$E_msgRuleExaYesReq = 'Please choose $minYesVars item(s).' ;
	$E_msgRuleMinYesMis = 'Please choose $minYesVars or more items.' ;
	$E_msgRuleMinMaxYesMis = 'Please choose between $minYesVars and $maxYesVars items.' ;
	$E_msgRuleMaxYesMis = 'Please choose no more than $maxYesVars item(s).' ;
	$E_msgRuleExaYesMis = 'Please choose $minYesVars item(s).' ;
	$E_msgSysSystemBusy = 'System Busy' ;
	$E_msgSysBackButton = 'Please click on your browser\'s Back button and try again.' ;

	$E_test = 0 ;							# Perform a test?
	$E_test1BakAddExt = '\'.1\'' ;
	$E_test1ErrAddExt = '@_=(localtime());\'.\'.$fwdVarValues{$E_recIDVar}.\'-\'.($_[5]+1900).\'-\'.($_[4]<9?\'0\':\'\').($_[4]+1).\'-\'.($_[3]<10?\'0\':\'\').($_[3]).\'-\'.($_[2]<10?\'0\':\'\').($_[2]).($_[1]<10?\'0\':\'\').($_[1]).($_[0]<10?\'0\':\'\').($_[0]).\'.csv\'' ;
	$E_test4WaitToUnlock = 10 ;
	$E_test8LogAddExt = '\'.log\'' ;

	# Initialize global associative arrays
	$unparsed_raw_data = '' ;			# Unparsed raw data sent by the caller
	%raw_data = () ;						# Parsed raw data sent by the caller

	%ansVarValues = () ;					# Variable name and value pairs for answered questions
	%fwdVarValues = () ;					# Forwarded variable name and value pairs
	%fwdVarFixups = () ;					# Variable name and fixup character pairs for forwarded answers
	%defVarValues = () ;					# Default variable name and value pairs
	%evlVarValues = () ;					# Evaluations run by the script and assigned to variables
	%qryVarValues = () ;					# Variable name and value pairs for loading an existing record
	%qryVarUTests = () ;					# User-defined tests for matching values
	%recVarValues = () ;					# Variable name and value pairs from an existing record
	%insVarValues = () ;					# Instructions for replacing variable values

	%scriptExprResults = () ;			# Results from expressions evaluated by the script
	%globalFields = () ;					# Global fields used internally
	%pageRules = () ;						# Rules used to update the page

	%rules = () ;							# Rules to run on the variables
	%rulErrs = () ;						# Errors generated by running the rules
	%rulWrns = () ;						# Warnings generated by running the rules
	%sysErrs = () ;						# Errors generated by the system

	# Initialize global arrays
	@varList = () ;						# A list containing ordered variable names sent by the page
	@varValues = () ;						# A list containing values of variables in the same order as @varList
	%varValues = () ;						# Merged variable values

	%mulRec = () ;							# Variable name and value pairs from multiple records

	srand (time|$$) if ($] < 5.004) ;	# Initialize random number generator

	# ---------------------------------------------------------------
	# Read and parse the data from the source into associative arrays
	# ---------------------------------------------------------------

	&ReadParse ;							# Read and parse data from the source and save in %raw_data

	# Check required and optional fields
	&VarDefinedOrDie ('E_version');	# E_version is always required
	&VersionCorrectOrDie ;				# Is the required version set correctly?
	&DataSrcCorrectOrDie ;				# Is the optional $E_dataSrc set correctly?
	&CheckReloadFileName ;				# Is E_reloadFileName set correctly?

	# If not set, load the data file and variable lists from the file
	# Do not test $raw_data{'E_varDefVal'} because it is empty when there is one variable
	if (!defined $raw_data{'E_dataFileName'} || $raw_data{'E_dataFileName'} eq '' || !defined $raw_data{'E_varList'} || $raw_data{'E_varList'} eq '')
	{
		# In order to load other field values, E_file must be defined
		if (defined $raw_data{'E_file'} && $raw_data{'E_file'} ne '')
		{
			# Load the page file into a string
			local $page = &ReadTextFile ($raw_data{'E_file'}) ;															# Load file into string

			# Only if not already specified
			if (!defined $raw_data{'E_dataFileName'} || $raw_data{'E_dataFileName'} eq '')
			{
				$raw_data{'E_dataFileName'} = &GetStandardTagAttributeValue ($page, 'E_dataFileName') ;		# Extract the data file path
			}

			# Both E_varList and E_varDefVal must be present to override the values in the file
			if (!defined $raw_data{'E_varList'} || $raw_data{'E_varList'} eq '' || !defined $raw_data{'E_varDefVal'} || $raw_data{'E_varDefVal'} eq '')
			{
				$raw_data{'E_varList'} = &GetStandardTagAttributeValue ($page, 'E_varList') ;						# Extract the variable list
				$raw_data{'E_varDefVal'} = &GetStandardTagAttributeValue ($page, 'E_varDefVal') ;				# Extract the default value list
				$raw_data{'E_varDefVal'} = '' if (!defined $raw_data{'E_varDefVal'}) ;								# Unable to extract empty values
			}

			# Only if not already specified
			if (!defined $raw_data{'E_reloadFileName'} || $raw_data{'E_reloadFileName'} eq '')
			{
				$raw_data{'E_reloadFileName'} = &GetStandardTagAttributeValue ($page, 'E_reloadFileName') ;	# Extract the reload file path
			}

			# Only if not already specified
			if (!defined $raw_data{'E_conf'} || $raw_data{'E_conf'} eq '')
			{
				$raw_data{'E_conf'} = &GetStandardTagAttributeValue ($page, 'E_conf') ;								# Extract the configuration file path
			}
		}
	}

	# Only permit the configuration file to specify sendmail options
	undef $raw_data{'E_sendMail'} if (defined $raw_data{'E_sendMail'}) ;
	undef $raw_data{'E_sendMailEnv'} if (defined $raw_data{'E_sendMailEnv'}) ;
	undef $raw_data{'E_sendMailProg'} if (defined $raw_data{'E_sendMailProg'}) ;
	undef $raw_data{'E_sendMailProgTo'} if (defined $raw_data{'E_sendMailProgTo'}) ;
	undef $raw_data{'E_sendMailProgCC'} if (defined $raw_data{'E_sendMailProgCC'}) ;
	undef $raw_data{'E_sendMailProgBCC'} if (defined $raw_data{'E_sendMailProgBCC'}) ;
	undef $raw_data{'E_sendMailProgFrom'} if (defined $raw_data{'E_sendMailProgFrom'}) ;
	undef $raw_data{'E_sendMailProgDate'} if (defined $raw_data{'E_sendMailProgDate'}) ;
	undef $raw_data{'E_sendMailProgSubj'} if (defined $raw_data{'E_sendMailProgSubj'}) ;
	undef $raw_data{'E_sendMailProgBody'} if (defined $raw_data{'E_sendMailProgBody'}) ;
	undef $raw_data{'E_sendMailMsgTo'} if (defined $raw_data{'E_sendMailMsgTo'}) ;
	undef $raw_data{'E_sendMailMsgCC'} if (defined $raw_data{'E_sendMailMsgCC'}) ;
	undef $raw_data{'E_sendMailMsgBCC'} if (defined $raw_data{'E_sendMailMsgBCC'}) ;
	undef $raw_data{'E_sendMailMsgFrom'} if (defined $raw_data{'E_sendMailMsgFrom'}) ;
	undef $raw_data{'E_sendMailMsgDate'} if (defined $raw_data{'E_sendMailMsgDate'}) ;
	undef $raw_data{'E_sendMailMsgSubj'} if (defined $raw_data{'E_sendMailMsgSubj'}) ;
	undef $raw_data{'E_sendMailMsgBody'} if (defined $raw_data{'E_sendMailMsgBody'}) ;
	undef $raw_data{'E_sendMailMsgBodyFile'} if (defined $raw_data{'E_sendMailMsgBodyFile'}) ;
	undef $raw_data{'E_sendMailErrorFatal'} if (defined $raw_data{'E_sendMailErrorFatal'}) ;

	# Default sendmail message date header (dd Mon yyyy hh:mm:ss -0000)
	# Time is always in GMT or UTC
	$E_sendMailMsgDate = '@_=(gmtime());($_[3]<10?\'0\'.$_[3]:$_[3]).\' \'.(\'Jan\',\'Feb\',\'Mar\',\'Apr\',\'May\',\'Jun\',\'Jul\',\'Aug\',\'Sep\',\'Oct\',\'Nov\',\'Dec\')[$_[4]].\' \'.($_[5]+1900).\' \'.($_[2]<10?\'0\'.$_[2]:$_[2]).\':\'.($_[1]<10?\'0\'.$_[1]:$_[1]).\':\'.($_[0]<10?\'0\'.$_[0]:$_[0]).\' -0000\'' ;

	# Maybe load the configuration file to override values in %raw_data
	if (defined $raw_data{'E_conf'} && $raw_data{'E_conf'} ne '')
	{
		# Load the configuration file and return the current file name
		local $fileName = &ReadConfFile ($raw_data{'E_conf'}, \%raw_data) ;

		# The configuration file can specify the first file
		if ($E_dataSrc eq $kDirect && (!defined $raw_data{'E_file'} || $raw_data{'E_file'} eq ''))
		{
			$raw_data{'E_file'} = $raw_data{$fileName} ;

			# If not set, load the data file and variable lists from the file
			# Do not test $raw_data{'E_varDefVal'} because it is empty when there is one variable
			if ($raw_data{'E_file'} ne '' && (!defined $raw_data{'E_dataFileName'} || $raw_data{'E_dataFileName'} eq '' || !defined $raw_data{'E_varList'} || $raw_data{'E_varList'} eq ''))
			{
				# Load the page file into a string
				local $page = &ReadTextFile ($raw_data{'E_file'}) ;														# Load file into string

				# Only if not already specified
				if (!defined $raw_data{'E_dataFileName'} || $raw_data{'E_dataFileName'} eq '')
				{
					$raw_data{'E_dataFileName'} = &GetStandardTagAttributeValue ($page, 'E_dataFileName') ;	# Extract the data file path
				}

				# Only if not already specified
				if (!defined $raw_data{'E_varList'} || $raw_data{'E_varList'} eq '' || !defined $raw_data{'E_varDefVal'} || $raw_data{'E_varDefVal'} eq '')
				{
					$raw_data{'E_varList'} = &GetStandardTagAttributeValue ($page, 'E_varList') ;					# Extract the variable list
					$raw_data{'E_varDefVal'} = &GetStandardTagAttributeValue ($page, 'E_varDefVal') ;			# Extract the default value list
					$raw_data{'E_varDefVal'} = '' if (!defined $raw_data{'E_varDefVal'}) ;							# Unable to extract empty values
				}

				# Only if not already specified
				if (!defined $raw_data{'E_reloadFileName'} || $raw_data{'E_reloadFileName'} eq '')
				{
					$raw_data{'E_reloadFileName'} = &GetStandardTagAttributeValue ($page, 'E_reloadFileName') ;	# Extract the reload file path
				}
			}
		}
	}

	# Handle fields without prefixes
	&AddPrefixToFields () ;

	# Handle skipping pages via a cross-page link
	if (defined $raw_data{'E_skipFileName'} && $raw_data{'E_skipFileName'} ne '')
	{
		$raw_data{'E_nextFileName'} = $raw_data{'E_skipFileName'} ;
	}

	# Check required fields
	&VarDefinedOrDie ('E_dataFileName') ;
	&VarDefinedOrDie ('E_varList') ;
	&VarDefinedOrDie ('E_varDefVal') ;

	# Check optional fields
	&ApplyRuleCorrectOrDie ;			# Is the optional $E_applyRule set correctly?
	&AllowNoResponseCorrectOrDie ;	# Is the optional $E_allowNoResponse set correctly?

	$E_cgiURL = &GetRawDataFieldValue ('E_cgiUrl', $E_cgiURL) ;				# Extract cgi URL
	$E_aspURL = &GetRawDataFieldValue ('E_aspUrl', $E_aspURL) ;				# Extract asp URL
	$E_scriptURL = &GetRawDataFieldValue ('E_scriptUrl', $E_scriptURL) ;	# Extract script URL
	if ($E_scriptURL eq '')
	{
		$E_scriptURL = ($E_cgiURL ne '' ? $E_cgiURL : $E_aspURL);
	}

	if ($E_dataSrc eq $kSurveyPage || $E_dataSrc eq $kScriptPage)
	{
		# Are we going forward or backward?
		$bDoNext = 'Yes' if (defined ($raw_data{'E_nextButton'}) || defined ($raw_data{'E_nextIgnoreWarnings'})) ;
		$bGoBack = 'Yes' if (defined ($raw_data{'E_backButton'})) ;

		# Are we reloading?
		$bReload = 'Yes' if (defined ($raw_data{'E_reloadButton'}) || defined ($raw_data{'E_calcButton'})) ;

		# Are we going to a bookmark?
		$bGotoBookmark = 'Yes' if (defined ($raw_data{'E_bookmarkButton'})) ;

		# Ignore warnings?
		$bIgnoreWarnings = 'Yes' if (defined ($raw_data{'E_nextIgnoreWarnings'})) ;

		if ($bDoNext ne 'Yes' && $bGoBack ne 'Yes' && $bReload ne 'Yes' && $bGotoBookmark ne 'Yes' && $bIgnoreWarnings ne 'Yes')
		{
			$bDoNext = 'Yes' ;
		}
	}

	# Get File locking parameters
	# Not specified until 3.6.0
	$E_useFlock = &GetRawDataFieldValue ('E_useFlock', $E_useFlock) ;
	$E_flockFileExt = &GetRawDataFieldValue ('E_flockFileExt', $E_flockFileExt) ;
	$E_fexistFileExt = &GetRawDataFieldValue ('E_fexistFileExt', $E_fexistFileExt) ;
	$E_fexistTimeOutThreshold = &GetRawDataFieldValue ('E_fexistTimeOutThreshold', $E_fexistTimeOutThreshold) ;
	$E_fexistWaitToTryAgain = &GetRawDataFieldValue ('E_fexistWaitToTryAgain', $E_fexistWaitToTryAgain) ;

	# Get Id file parameters
	# Not specified until 3.6.0
	$E_idFileExt = &GetRawDataFieldValue ('E_idFileExt', $E_idFileExt) ; # Extract id file filename extension

	# Get Index file parameters
	# Not specified until 3.6.0
	$E_useIndexFile = &GetRawDataFieldValue ('E_useIndexFile', $E_useIndexFile) ; # Extract use index file option
	$E_indexFileExt = &GetRawDataFieldValue ('E_indexFileExt', $E_indexFileExt) ; # Extract index file filename extension
	$E_indexFileMinBufSize = &GetRawDataFieldValue ('E_indexFileMinBufSize', $E_indexFileMinBufSize) ; # Extract minimum index file buffer size
	$E_indexFileMaxBufSize = &GetRawDataFieldValue ('E_indexFileMaxBufSize', $E_indexFileMaxBufSize) ; # Extract maximum index file buffer size

	# Get optional parameters
	$E_clearOnDiffRecord = &GetRawDataFieldValue ('E_clearOnDiffRecord', $E_clearOnDiffRecord) ;
	$E_decimalPoint = &GetRawDataFieldValue ('E_decimalPoint', $E_decimalPoint) ;
	$E_writeOnNext = &GetRawDataFieldValue ('E_writeOnNext', $E_writeOnNext) ;

	# Get Sendmail parameters
	# Not specified until 3.2.1
	$E_sendMail = &GetRawDataFieldValue ('E_sendMail', $E_sendMail);
	$E_sendMailEnv = &GetRawDataFieldValue ('E_sendMailEnv', $E_sendMailEnv);
	$E_sendMailProg = &GetRawDataFieldValue ('E_sendMailProg', $E_sendMailProg);
	$E_sendMailProgTo = &TagDecodeText (&GetRawDataFieldValue ('E_sendMailProgTo', $E_sendMailProgTo));
	$E_sendMailProgCC = &TagDecodeText (&GetRawDataFieldValue ('E_sendMailProgCC', $E_sendMailProgCC));
	$E_sendMailProgBCC = &TagDecodeText (&GetRawDataFieldValue ('E_sendMailProgBCC', $E_sendMailProgBCC));
	$E_sendMailProgFrom = &TagDecodeText (&GetRawDataFieldValue ('E_sendMailProgFrom', $E_sendMailProgFrom));
	$E_sendMailProgDate = &TagDecodeText (&GetRawDataFieldValue ('E_sendMailProgDate', $E_sendMailProgDate));
	$E_sendMailProgSubj = &TagDecodeText (&GetRawDataFieldValue ('E_sendMailProgSubj', $E_sendMailProgSubj));
	$E_sendMailProgBody = &TagDecodeText (&GetRawDataFieldValue ('E_sendMailProgBody', $E_sendMailProgBody));
	$E_sendMailMsgTo = &TagDecodeText (&GetRawDataFieldValue ('E_sendMailMsgTo', $E_sendMailMsgTo));
	$E_sendMailMsgCC = &TagDecodeText (&GetRawDataFieldValue ('E_sendMailMsgCC', $E_sendMailMsgCC));
	$E_sendMailMsgBCC = &TagDecodeText (&GetRawDataFieldValue ('E_sendMailMsgBCC', $E_sendMailMsgBCC));
	$E_sendMailMsgFrom = &TagDecodeText (&GetRawDataFieldValue ('E_sendMailMsgFrom', $E_sendMailMsgFrom));
	$E_sendMailMsgDate = &TagDecodeText (&GetRawDataFieldValue ('E_sendMailMsgDate', $E_sendMailMsgDate));
	$E_sendMailMsgSubj = &TagDecodeText (&GetRawDataFieldValue ('E_sendMailMsgSubj', $E_sendMailMsgSubj));
	$E_sendMailMsgBody = &TagDecodeText (&GetRawDataFieldValue ('E_sendMailMsgBody', $E_sendMailMsgBody));
	$E_sendMailMsgBodyFile = &TagDecodeText (&GetRawDataFieldValue ('E_sendMailMsgBodyFile', $E_sendMailMsgBodyFile));
	# Not specified until 3.5.0
	$E_sendMailErrorFatal = &TagDecodeText (&GetRawDataFieldValue ('E_sendMailErrorFatal', $E_sendMailErrorFatal));

	# Not specified until 3.1.0
	$E_msgRuleNotNum = &GetRawDataFieldValue ('E_msgRuleNotNum', $E_msgRuleNotNum) ;
	$E_msgRuleMinNum = &GetRawDataFieldValue ('E_msgRuleMinNum', $E_msgRuleMinNum) ;
	$E_msgRuleMaxNum = &GetRawDataFieldValue ('E_msgRuleMaxNum', $E_msgRuleMaxNum) ;
	$E_msgRulePosNum = &GetRawDataFieldValue ('E_msgRulePosNum', $E_msgRulePosNum) ;
	$E_msgRuleRnkOne = &GetRawDataFieldValue ('E_msgRuleRnkOne', $E_msgRuleRnkOne) ;
	$E_msgRuleRnkGap = &GetRawDataFieldValue ('E_msgRuleRnkGap', $E_msgRuleRnkGap) ;
	$E_msgRuleCsmSum = &GetRawDataFieldValue ('E_msgRuleCsmSum', $E_msgRuleCsmSum) ;
	$E_msgRuleReqRsp = &GetRawDataFieldValue ('E_msgRuleReqRsp', $E_msgRuleReqRsp) ;
	$E_msgRuleMisRsp = &GetRawDataFieldValue ('E_msgRuleMisRsp', $E_msgRuleMisRsp) ;

	# Not specified until 3.2.1
	$E_msgRuleMinReq = &GetRawDataFieldValue ('E_msgRuleMinReq', $E_msgRuleMinReq) ;
	$E_msgRuleMaxReq = &GetRawDataFieldValue ('E_msgRuleMaxReq', $E_msgRuleMaxReq) ;
	$E_msgRuleMinMis = &GetRawDataFieldValue ('E_msgRuleMinMis', $E_msgRuleMinMis) ;
	$E_msgRuleMaxMis = &GetRawDataFieldValue ('E_msgRuleMaxMis', $E_msgRuleMaxMis) ;
	$E_msgSysCantLock = &GetRawDataFieldValue ('E_msgSysCantLock', $E_msgSysCantLock) ;

	# Not specified until 3.4.0
	$E_msgRuleMinYesReq = &GetRawDataFieldValue ('E_msgRuleMinYesReq', $E_msgRuleMinYesReq) ;
	$E_msgRuleMinMaxYesReq = &GetRawDataFieldValue ('E_msgRuleMinMaxYesReq', $E_msgRuleMinMaxYesReq) ;
	$E_msgRuleMaxYesReq = &GetRawDataFieldValue ('E_msgRuleMaxYesReq', $E_msgRuleMaxYesReq) ;
	$E_msgRuleExaYesReq = &GetRawDataFieldValue ('E_msgRuleExaYesReq', $E_msgRuleExaYesReq) ;
	$E_msgRuleMinYesMis = &GetRawDataFieldValue ('E_msgRuleMinYesMis', $E_msgRuleMinYesMis) ;
	$E_msgRuleMinMaxYesMis = &GetRawDataFieldValue ('E_msgRuleMinMaxYesMis', $E_msgRuleMinMaxYesMis) ;
	$E_msgRuleMaxYesMis = &GetRawDataFieldValue ('E_msgRuleMaxYesMis', $E_msgRuleMaxYesMis) ;
	$E_msgRuleExaYesMis = &GetRawDataFieldValue ('E_msgRuleExaYesMis', $E_msgRuleExaYesMis) ;
	$E_msgRuleMinMaxReq = &GetRawDataFieldValue ('E_msgRuleMinMaxReq', $E_msgRuleMinMaxReq) ;
	$E_msgRuleMinMaxMis = &GetRawDataFieldValue ('E_msgRuleMinMaxMis', $E_msgRuleMinMaxMis) ;
	$E_msgRuleExaReq = &GetRawDataFieldValue ('E_msgRuleExaReq', $E_msgRuleExaReq) ;
	$E_msgRuleExaMis = &GetRawDataFieldValue ('E_msgRuleExaMis', $E_msgRuleExaMis) ;
	$E_msgRuleAllReq = &GetRawDataFieldValue ('E_msgRuleAllReq', $E_msgRuleAllReq) ;
	$E_msgRuleAllMis = &GetRawDataFieldValue ('E_msgRuleAllMis', $E_msgRuleAllMis) ;

	# Not specified until 3.6.0
	$E_msgSysSystemBusy = &GetRawDataFieldValue ('E_msgSysSystemBusy', $E_msgSysSystemBusy) ;
	$E_msgSysBackButton = &GetRawDataFieldValue ('E_msgSysBackButton', $E_msgSysBackButton) ;
	
	# Not specified by application
	$E_test = &GetRawDataFieldValue ('E_test', $E_test) ;
	$E_test1BakAddExt = &GetRawDataFieldValue ('E_test1BakAddExt', $E_test1BakAddExt) ;
	$E_test1ErrAddExt = &GetRawDataFieldValue ('E_test1ErrAddExt', $E_test1ErrAddExt) ;
	$E_test4WaitToUnlock = &GetRawDataFieldValue ('E_test4WaitToUnlock', $E_test4WaitToUnlock) ;
	$E_test8LogAddExt = &GetRawDataFieldValue ('E_test8LogAddExt', $E_test8LogAddExt) ;

	# Extract record id column information
	$E_useRecID = &GetRawDataFieldValue ('E_useRecID', $E_useRecID) ;
	if ($E_useRecID eq 'Yes')
	{
		$E_recIDVar = &GetRawDataFieldValue ('E_recIDVar', $E_recIDVar) ;
	}
	else
	{
		$E_recIDVar = '' ;
	}

	# Extract record counter column information
	$E_useRecCnt = &GetRawDataFieldValue ('E_useRecCnt', $E_useRecCnt) ;
	if ($E_useRecCnt eq 'Yes')
	{
		$E_recCntVar = &GetRawDataFieldValue ('E_recCntVar', $E_recCntVar) ;
	}
	else
	{
		$E_recCntVar = '' ;
	}

	$E_useMulRec = &GetRawDataFieldValue ('E_useMulRec', $E_useMulRec) ;				# Extract multi-record support
	$E_maxMulRecs = &GetRawDataFieldValue ('E_maxMulRecs', $E_maxMulRecs) ;			# Extract multi-record support
	$E_matchEmpty = &GetRawDataFieldValue ('E_matchEmpty', $E_matchEmpty) ;			# Extract match empty values
	$E_alwaysGetRec = &GetRawDataFieldValue ('E_alwaysGetRec', $E_alwaysGetRec) ; # Extract always get records
	$E_checkTimeStamp = &GetRawDataFieldValue ('E_checkTimeStamp', $E_checkTimeStamp) ;	# Extract the check time stamp option
	$E_timeStamp = &GetRawDataFieldValue ('E_timeStamp', $E_timeStamp) ;				# Extract the time stamp
	$E_bookmarking = &GetRawDataFieldValue ('E_bookmarking', $E_bookmarking) ;		# Extract the bookmarking option
	$E_allowPageSkipping = &GetRawDataFieldValue ('E_allowPageSkipping', $E_allowPageSkipping) ;	# Extract the page skipping option
	$E_getRecIDDirect = &GetRawDataFieldValue ('E_getRecIDDirect', $E_getRecIDDirect) ; # Extract okay to use the record id to get records when called directly?

	$E_file = &GetRawDataFieldValue ('E_file', $E_file) ;									# Extract the page path
	$E_dataFileName = &GetRawDataFieldValue ('E_dataFileName', $E_dataFileName) ;	# Extract the data file path
	$E_varList = &GetRawDataFieldValue ('E_varList', $E_varList) ;						# Extract variable name list
	$E_varDefVal = &GetRawDataFieldValue ('E_varDefVal', $E_varDefVal) ;				# Extract default value list
	$E_varFwdVal = &GetRawDataFieldValue ('E_varFwdVal', $E_varFwdVal) ;				# Extract forward value list

	# Compare against the time stamp of the file on the server
	# The calling page may be an older cached version
	&GetReloadFileName ;																				# Extract the survey page file name to reload
	if ($E_checkTimeStamp eq 'Yes' && $E_reloadFileName ne '' && $E_timeStamp ne '')
	{
		local $page = &ReadTextFile ($E_reloadFileName) ;									# Load file into string
		local $timeStamp = &GetStandardTagAttributeValue ($page, 'E_timeStamp') ;	# Extract the time stamp
		if ($E_timeStamp ne $timeStamp)
		{
			&DieMsg ("Fatal Error",
						"The script cannot process your survey. ".
						"The time stamp on the submitted survey page (" . &HTMLEncodeText ($E_timeStamp) . ") does not match the time stamp on (" . &HTMLEncodeText ($E_reloadFileName) . "). ".
						"The submitted survey page may be an older version cached by your browser. ".
						"Please click on your browser's Back button, click on the Refresh or Reload button and try again. ".
						"If this error appears again, please contact this site's webmaster.") ;
		}
	}
	
	# Add record counter column to variable name, default value and forward value lists
	if ($E_recCntVar ne '' && $E_dataSrc ne $kScriptPage)
	{
		$E_varList = $E_recCntVar . ',' . $E_varList ;
		$E_varDefVal = ',' . $E_varDefVal ;
		if ($E_varFwdVal ne '')
		{
			$E_varFwdVal = ',' . $E_varFwdVal ;
		}
	}

	# Add record id column to variable name, default value and forward value lists
	if ($E_recIDVar ne '' && $E_dataSrc ne $kScriptPage)
	{
		$E_varList = $E_recIDVar . ',' . $E_varList ;
		$E_varDefVal = ',' . $E_varDefVal ;
		if ($E_varFwdVal ne '')
		{
			$E_varFwdVal = ',' . $E_varFwdVal ;
		}
	}

	# Extract variable name and value pairs into associative arrays
	if ($E_varFwdVal ne '')
	{
		&GetFwdVarValues ($E_varList, $E_varFwdVal);	# Extract forwarded variable values from %raw_data
		&GetFwdVarFixups ;									# Extract forwarded fixup values from %raw_data
		&FixupFwdVarValues ;									# Fixup forwarded values that contain special characters
	}

	&GetGlobalFields ;										# Extract global fields from %raw_data

	&GetAnsVarValues ;										# Extract variable values from %raw_data
	&GetDefVarValues ($E_varList, $E_varDefVal) ;	# Extract default variable values
	&GetInsVarValues ;										# Extract replacement instructions from %raw_data
	&GetEvlVarValues ;										# Extract and evaluate variable values from %raw_data
	&GetEvlGlbFields ;										# Extract and evaluate global fields from %raw_data
	&GetQryVarValues ;										# Extract query variable values from %raw_data
	&GetQryVarUTests ;										# Extract user-defined query variable tests from %raw_data
	{
		# GetPreQryVarValues uses %raw_data, %ansVarValues, %fwdVarValues, %defVarValues and %insVarValues
		local ($ret) = &GetPreQryVarValues ;			# Extract query variables from %ansVarValues and %raw_data
		if ($ret eq 'changed')
		{
			$bQueryChanged = 'Yes' ;						# Mark the query changed
		}

		if ($E_clearOnDiffRecord eq 'Yes' && %qryVarValues && ($bQueryChanged eq 'Yes' || $E_alwaysGetRec eq 'Yes' || !defined ($globalFields{$kg_GetRecVarValues})))
		{
			# We are throwing out the old record and loading a new and different one
			# Clear the forwarded variables to allow the new record values to appear
			%fwdVarValues = () ;								# Clear %fwdVarValues associative array
			%fwdVarFixups = () ;								# Clear %fwdVarFixups associative array
		}
	}

	# Maybe add another extension to the data file name
	$E_dataFileAddExt = &EvalRawDataFieldValue ('E_dataFileAddExt', $E_dataFileAddExt) ;	# Extract the additional data file path extension
	if ($E_dataFileAddExt ne '')
	{
		$E_dataFileName = $E_dataFileName . $E_dataFileAddExt ;				# Add extension to the data file path
	}

	# Automatically create the data file?	
	if ($bCreateDataFile ne 'Yes')
	{
		# If not allowed to automatically create the data file, the data file must exist
		(-e $E_dataFileName) || &DieMsg ("Fatal Error", "The script cannot process your survey because the data file (" . &HTMLEncodeText ($E_dataFileName) . ") does not exist.", "Please contact this site's webmaster.") ;
	}

	# Does %fwdVarValues have an uninitialized value for record id?
	if ($E_recIDVar ne '' && (!%fwdVarValues || $fwdVarValues{$E_recIDVar} eq ''))
	{
		# Get the next record id
		local ($lockHandle, $lockPath, $lockMode) = &LockFile ($E_dataFileName, 2) ;	# Wait for an exclusive lock
		$fwdVarValues{$E_recIDVar} = &GetNextRecID ($E_dataFileName, $E_recIDVar, $E_recCntVar) ;
		&UnlockFile ($lockHandle, $lockPath, $lockMode) ;										# Release the exclusive lock

		# Does %fwdVarValues have an uninitialized value for record counter?
		if ($E_recCntVar ne '' && (!%fwdVarValues || $fwdVarValues{$E_recCntVar} eq ''))
		{
			$fwdVarValues{$E_recCntVar} = '1' ;
		}
	}

	# Does %fwdVarValues have an uninitialized value for record counter?
	if ($E_recCntVar ne '' && (!%fwdVarValues || $fwdVarValues{$E_recCntVar} eq ''))
	{
		local ($lockHandle, $lockPath, $lockMode) = &LockFile ($E_dataFileName, 2) ;	# Wait for an exclusive lock
		&MaybeFixDataFile ($E_dataFileName, $E_recIDVar, $E_recCntVar, 1) ;				# Maybe add columns for the record id and completion counter
		&UnlockFile ($lockHandle, $lockPath, $lockMode) ;										# Release the exclusive lock

		$fwdVarValues{$E_recCntVar} = '1' ;
	}
	
	if ($E_recIDVar ne '' && !%qryVarValues && $fwdVarValues{$E_recIDVar} ne '' && ($E_dataSrc ne $kDirect || $E_getRecIDDirect eq 'Yes'))
	{
		# Add the next record id to the query values list
		$qryVarValues{$E_recIDVar} = $fwdVarValues{$E_recIDVar} ;
		$bQueryChanged = 'Yes' ;									# Mark the query changed
	}

	local $bCalledGetRec = 0 ;
	if (%qryVarValues && ($bQueryChanged eq 'Yes' || $E_alwaysGetRec eq 'Yes' || !defined ($globalFields{$kg_GetRecVarValues})))
	{
		local $gotRec = &GetRecVarValues ($E_dataFileName) ;
		if ($gotRec ne 'true' && (defined ($globalFields{$kg_GetRecVarValues}) && $globalFields{$kg_GetRecVarValues} eq 'true'))
		{
			# Get the next record id
			local ($lockHandle, $lockPath, $lockMode) = &LockFile ($E_dataFileName, 2) ;	# Wait for an exclusive lock
			$fwdVarValues{$E_recIDVar} = &GetNextRecID ($E_dataFileName, $E_recIDVar, $E_recCntVar) if ($E_recIDVar ne '') ;
			&UnlockFile ($lockHandle, $lockPath, $lockMode) ;										# Release the exclusive lock

			# Reset the counter
			$fwdVarValues{$E_recCntVar} = '1' if ($E_recCntVar ne '') ;
		}
		elsif ($gotRec eq 'true')							# Maybe load variable values from the data file
		{
			$fwdVarValues{$E_recIDVar} = $recVarValues{$E_recIDVar} if ($E_recIDVar ne '') ;
			if ($E_recCntVar ne '')
			{
				if ($recVarValues{$E_recCntVar} =~ m/^\d+$E_decimalPoint\d+$/)
				{
					local ($recCnt, $bookmarkPageNum) = ($recVarValues{$E_recCntVar} =~ m/^(\d+)$E_decimalPoint(\d+)$/) ;
					$recCnt++;
					$recVarValues{$E_recCntVar} = $recCnt . $E_decimalPoint . $bookmarkPageNum ;
				}
				else
				{
					$recVarValues{$E_recCntVar}++ ;
				}
				$fwdVarValues{$E_recCntVar} = $recVarValues{$E_recCntVar} ;
			}
			&TrimRecVarValues ;								# Remove variables that are on the current form
		}
		$globalFields{$kg_GetRecVarValues} = $gotRec ;
		$bCalledGetRec = 1 ;
	}

	&MergeVarValues ;											# Merge all variable values into @varValues and %varValues

	&DoUserCommands ('C_') ;								# Extracts and processes user command scripts from %raw_data
	&DoUserCommands ('CMD_') ;								# Extracts and processes user command scripts from %raw_data

	$E_getRecCnt = &GetRawDataFieldValue ('E_getRecCnt', $E_getRecCnt) ;		# Extract get record count
	if (%qryVarValues && !$bCalledGetRec && $E_getRecCnt eq 'Yes')
	{
		local $gotRec = &GetRecVarValues ($E_dataFileName) ;
		local $bUpdateVarValues = 0 ;
		if ($gotRec ne 'true' && (defined ($globalFields{$kg_GetRecVarValues}) && $globalFields{$kg_GetRecVarValues} eq 'true'))
		{
			# Get the next record id
			local ($lockHandle, $lockPath, $lockMode) = &LockFile ($E_dataFileName, 2) ;	# Wait for an exclusive lock
			$fwdVarValues{$E_recIDVar} = &GetNextRecID ($E_dataFileName, $E_recIDVar, $E_recCntVar) if ($E_recIDVar ne '') ;
			&UnlockFile ($lockHandle, $lockPath, $lockMode) ;										# Release the exclusive lock

			# Reset the counter
			$fwdVarValues{$E_recCntVar} = '1' if ($E_recCntVar ne '') ;
			$bUpdateVarValues = 1 ;							# Update @varValues and %varValues
		}
		elsif ($gotRec eq 'true')							# Maybe update the record id and counter variables
		{
			$fwdVarValues{$E_recIDVar} = $recVarValues{$E_recIDVar} if ($E_recIDVar ne '') ;
			if ($E_recCntVar ne '')
			{
				if ($recVarValues{$E_recCntVar} =~ m/^\d+$E_decimalPoint\d+$/)
				{
					local ($recCnt, $bookmarkPageNum) = ($recVarValues{$E_recCntVar} =~ m/^(\d+)$E_decimalPoint(\d+)$/) ;
					$recCnt++;
					$recVarValues{$E_recCntVar} = $recCnt . $E_decimalPoint . $bookmarkPageNum ;
				}
				else
				{
					$recVarValues{$E_recCntVar}++ ;
				}
				$fwdVarValues{$E_recCntVar} = $recVarValues{$E_recCntVar} ;
			}
			%recVarValues = () ;								# Clear the record values array
			$bUpdateVarValues = 1 ;							# Update @varValues and %varValues
		}

		if ($bUpdateVarValues)
		{
			if ($E_recIdVar ne '')
			{
				local $pos = &GetVarListPos ($E_recIDVar) ;	# Get the record id variable position
				$varValues[$pos] = $fwdVarValues{$E_recIDVar} if ($pos >= 0) ;
				$varValues{$E_recIDVar} = $fwdVarValues{$E_recIDVar} ;
			}

			if ($E_recCntVar ne '')
			{
				local $pos = &GetVarListPos ($E_recCntVar) ;	# Get the record count variable position
				$varValues[$pos] = $fwdVarValues{$E_recCntVar} if ($pos >= 0) ;
				$varValues{$E_recCntVar} = $fwdVarValues{$E_recCntVar} ;
			}
		}
	}

	&GetNextFileName ;										# Extract the next survey page file name
	&GetBackFileName ;										# Extract the back survey page file name list
	&GetBookmarkOnBack ;										# Extract the bookmark on back values

	# ----------------------
	# Handle bookmark button
	# ----------------------

	if ($bGotoBookmark eq 'Yes')							# Going to a bookmarked page?
	{
		if ($fwdVarValues{$E_recCntVar} =~ m/^\d+$E_decimalPoint\d+$/)
		{
			local ($bookmarkPageNum) = ($fwdVarValues{$E_recCntVar} =~ m/^\d+$E_decimalPoint(\d+)$/) ;
			local $fileField = 'E_fileName_' . $bookmarkPageNum ;
			if (defined ($raw_data{$fileField}))		# Does the bookmarked file field exist?
			{
				$E_bookmarkFileName = $raw_data{$fileField} ;
				$E_bookmarkFileField = $fileField ;
			}
		}

		if ($E_bookmarkFileName eq '')
		{
			$bGotoBookmark = 'No' ;							# Cannot find the bookmarked file field
			$bReload = 'Yes' ;								# Reload instead
		}
	}

	# -----------------------------------
	# Run the rules (survey callers only)
	# -----------------------------------

	local $loadFileName = '' ;								# Path of the file to load next
	local $loadFileField = '' ;							# Field of the file to load next
	if ($bDoNext eq 'Yes' || $bGotoBookmark eq 'Yes')	# Only run the rules if going forward
	{
		if ($E_applyRule eq 'Yes' && (!defined ($globalFields{$kg_ApplyRule}) || $globalFields{$kg_ApplyRule} eq 'Yes'))	# Run the rules?
		{
			&GetRules ;											# Extract the rules from %raw_data
			local $ret = &RunRules ($kSaving);			# Run the rules on %ansVarValues

			if (($ret eq "Warnings" && $bIgnoreWarnings eq 'No') || $ret eq "Errors")
			{
				# We have warnings and/or errors
				$loadFileName = $E_reloadFileName ;		# Reload the page later
				$loadFileField = $E_reloadFileField ;
				$bReloadingPage = 'Yes' ;					# We are reloading the page
			}
		}
	}
	elsif ($bReload eq 'Yes')
	{
		if ($E_applyRule eq 'Yes' && defined ($raw_data{'E_reloadButton'}) && (!defined ($globalFields{$kg_ApplyRule}) || $globalFields{$kg_ApplyRule} eq 'Yes'))
		{
			&GetRules ;											# Extract the rules from %raw_data
			&RunRules ($kSaving);							# Run the rules on %ansVarValues
		}

		# May have warnings and/or errors
		$loadFileName = $E_reloadFileName ;				# Reload the page later
		$loadFileField = $E_reloadFileField ;
		$bReloadingPage = 'Yes' ;							# We are reloading the page
	}

	# --------------------
	# Handle page skipping
	# --------------------
	
	if ($E_allowPageSkipping eq 'Yes' && $bReloadingPage ne 'Yes' && ($bDoNext eq 'Yes' || $bGotoBookmark eq 'Yes'))
	{
		if ($bDoNext eq 'Yes')
		{
			if ($E_nextFileName ne '')
			{
				($E_nextFileField, $E_nextFileName) = &MaybeSkipNextPage ($E_nextFileField, $E_nextFileName) ;
			}
		}
		else
		{
			if ($E_bookmarkFileName ne '')
			{
				($E_bookmarkFileField, $E_bookmarkFileName) = &MaybeSkipNextPage ($E_bookmarkFileField, $E_bookmarkFileName) ;
			}
		}
	}

	# -------------------------
	# Bookmark current position
	# -------------------------

	if ($E_bookmarking eq 'Yes' && $E_writeOnNext eq 'Yes' && $E_recCntVar ne '' && $bReloadingPage ne 'Yes' && ($bDoNext eq 'Yes' || ($bGoBack eq 'Yes' && ($#E_bookmarkOnBack < 0 || $E_bookmarkOnBack[0] ne 'No'))))
	{
		local $recCnt = 0 ;
		local $bookmarkPageNum = -1 ;
		if ($fwdVarValues{$E_recCntVar} =~ m/^\d+$E_decimalPoint\d+$/)
		{
			($recCnt, $bookmarkPageNum) = ($fwdVarValues{$E_recCntVar} =~ m/^(\d+)$E_decimalPoint(\d+)$/) ;
		}
		else
		{
			$recCnt = $fwdVarValues{$E_recCntVar} ;
		}

		if ($E_reloadFileField =~ m/^E_fileName_\d+$/)
		{
			local ($reloadPageNum) = ($E_reloadFileField =~ m/^E_fileName_(\d+)$/) ;
			if ($bookmarkPageNum == -1 || $bookmarkPageNum == $reloadPageNum || !defined ($raw_data{'E_fileName_' . $bookmarkPageNum}) || (defined ($raw_data{'E_resetBookmark'}) && $raw_data{'E_resetBookmark'} eq 'Yes'))
			{
				local $gotoPageNum = -1 ;
				if ($bDoNext eq 'Yes')
				{
					if ($E_nextFileField =~ m/^E_fileName_\d+$/)
					{
						($gotoPageNum) = ($E_nextFileField =~ m/^E_fileName_(\d+)$/) ;
					}
				}
				elsif ($bGoBack eq 'Yes')
				{
					if  ($#E_backFileName >= 0)
					{
						if ($E_backFileName[0] =~ m/^E_fileName_\d+$/)
						{
							($gotoPageNum) = ($E_backFileName[0] =~ m/^E_fileName_(\d+)$/) ;
						}
					}
				}

				if ($gotoPageNum != -1)
				{
					$fwdVarValues{$E_recCntVar} = $recCnt . $E_decimalPoint . $gotoPageNum ;
				}
				else
				{
					$fwdVarValues{$E_recCntVar} = $recCnt ;
				}
			}
		}
		else
		{
			$fwdVarValues{$E_recCntVar} = $recCnt ;
		}

		local $pos = GetVarListPos ($E_recCntVar) ;	# Get the record count variable position
		$varValues[$pos] = $fwdVarValues{$E_recCntVar} if ($pos >= 0) ;
		$varValues{$E_recCntVar} = $fwdVarValues{$E_recCntVar} ;
	}

	# --------------------
	# Write to a log file?
	# --------------------

	if ($E_test & 8)
	{
		local $logPath = $E_dataFileName . &SafeEval (&ExpandShortVarRefs ($E_test8LogAddExt)) ;
		local ($lockHandle, $lockPath, $lockMode) = &LockFile ($logPath, 2);
		&AppendTextFile ($logPath, ";-------------------------Log Entry " . &XF_FORMAT_LOCALTIME (1, 3) . "-------------------------\n") ;
		&AppendTextFile ($logPath, "[Version]\nVersion=1.0.0\n\n") ;
		&AppendTextFile ($logPath, "[Environment]\n") ;
		&AppendTextFile ($logPath, "REMOTE_ADDR", &XF_WEBSERVER_ENV ("REMOTE_ADDR") . "\n") ;
		&AppendTextFile ($logPath, "HTTP_USER_AGENT", &XF_WEBSERVER_ENV ("HTTP_USER_AGENT") . "\n\n") ;
		&AppendTextFile ($logPath, "[unparsed_raw_data]\n" . $unparsed_raw_data . "\n\n") ;
		&AppendTextFile ($logPath, "[raw_data]\n") ;
		&AppendTextFile ($logPath, %raw_data) ;
		&AppendTextFile ($logPath, "\n\n[fwdVarValues]\n") ;
		&AppendTextFile ($logPath, %fwdVarValues) ;
		&AppendTextFile ($logPath, "\n\n[fwdVarFixups]\n") ;
		&AppendTextFile ($logPath, %fwdVarFixups) ;
		&AppendTextFile ($logPath, "\n\n[ansVarValues]\n") ;
		&AppendTextFile ($logPath, %ansVarValues) ;
		&AppendTextFile ($logPath, "\n\n[insVarValues]\n") ;
		&AppendTextFile ($logPath, %insVarValues) ;
		&AppendTextFile ($logPath, "\n\n[qryVarValues]\n") ;
		&AppendTextFile ($logPath, %qryVarValues) ;
		&AppendTextFile ($logPath, "\n\n[defVarValues]\n") ;
		&AppendTextFile ($logPath, %defVarValues) ;
		&AppendTextFile ($logPath, "\n\n[evlVarValues]\n") ;
		&AppendTextFile ($logPath, %evlVarValues) ;
		&AppendTextFile ($logPath, "\n\n[varValues]\n") ;
		&AppendTextFile ($logPath, %varValues) ;
		&AppendTextFile ($logPath, "\n\n") ;
		&UnlockFile ($lockHandle, $lockPath, $lockMode) ;
	}

	# ------------------------------------------------
	# Process the data or determine which page to load
	# ------------------------------------------------
	if ($loadFileName eq '')								# Did running the rules cause us to reload the page?
	{
		if ($bGotoBookmark eq 'Yes')						# Going to a bookmarked page?
		{
			@E_bookmarkOnBack = () ;						# Clear the value list
			unshift (@E_bookmarkOnBack, 'No') ;			# Add to the beginning of the value list
		}
		elsif ($#E_bookmarkOnBack >= 0)					# Have we ever used the bookmark button to go to the bookmarked page?
		{
			if ($bDoNext eq 'Yes')							# Going to the next page?
			{
				unshift (@E_bookmarkOnBack, 'Yes') ;	# Add to the beginning of the value list
			}
			elsif ($bGoBack eq 'Yes')						# Going backward?
			{
				shift (@E_bookmarkOnBack) ;				# Remove value from the beginning of the list
			}
		}

		if ($bDoNext eq 'Yes')								# Going to the next page?
		{
			if ($E_nextFileName eq '')						# Empty means dump to data file
			{
				local $err = &WriteDataFile_2 ($E_dataFileName, 'Yes') ;	# Append to or update the data file
				if ($err == 0)
				{
					local $page = &CreateSuccessPage ;		# Generate the confirmation page
					if ($E_test & 8)
					{
						local $logPath = $E_dataFileName . &SafeEval (&ExpandShortVarRefs ($E_test8LogAddExt)) ;
						local ($lockHandle, $lockPath, $lockMode) = &LockFile ($logPath, 2);
						&AppendTextFile ($logPath, "[Output]\n" . $page . "\n\n") ;
						&UnlockFile ($lockHandle, $lockPath, $lockMode) ;
					}
					&SendToOutput ($page) ;						# Send the confirmation page
				}
				else
				{
					$loadFileName = $E_reloadFileName ;		# Reload the page later
					$loadFileField = $E_reloadFileField ;
					$bReloadingPage = 'Yes' ;					# We are reloading the page
				}
			}
			elsif ($E_dataSrc eq $kDirect)				# Called directly?
			{
				$loadFileName = $E_nextFileName ;		# Load the next page later
				$loadFileField = $E_nextFileField ;
				# Leave back filename list as it is
			}
			elsif ($E_dataSrc eq $kSurveyPage || $E_dataSrc eq $kScriptPage)
			{
				$loadFileName = $E_nextFileName ;		# Load the next page later
				$loadFileField = $E_nextFileField ;
				if ($E_writeOnNext eq 'Yes')
				{
					&WriteDataFile_2 ($E_dataFileName, 'No') ;	# Append to or update the data file
				}
				# Add to the beginning of the back filename list
				unshift (@E_backFileName, $E_reloadFileField) ;
			}
		}
		elsif ($bGotoBookmark eq 'Yes')					# Going to a bookmarked page?
		{
			if ($E_bookmarkFileName eq '')				# Empty means dump to data file
			{
				local $err = &WriteDataFile_2 ($E_dataFileName, 'Yes') ;	# Append to or update the data file
				if ($err == 0)
				{
					local $page = &CreateSuccessPage ;		# Generate the confirmation page
					if ($E_test & 8)
					{
						local $logPath = $E_dataFileName . &SafeEval (&ExpandShortVarRefs ($E_test8LogAddExt)) ;
						local ($lockHandle, $lockPath, $lockMode) = &LockFile ($logPath, 2);
						&AppendTextFile ($logPath, "[Output]\n" . $page . "\n\n") ;
						&UnlockFile ($lockHandle, $lockPath, $lockMode) ;
					}
					&SendToOutput ($page) ;						# Send the confirmation page
				}
				else
				{
					$loadFileName = $E_reloadFileName ;		# Reload the page later
					$loadFileField = $E_reloadFileField ;
					$bReloadingPage = 'Yes' ;					# We are reloading the page
				}
			}
			elsif ($E_dataSrc eq $kDirect)				# Called directly?
			{
				$loadFileName = $E_bookmarkFileName ;	# Load the bookmarked page later
				$loadFileField = $E_bookmarkFileField ;
				# Leave back filename list as it is
			}
			elsif ($E_dataSrc eq $kSurveyPage || $E_dataSrc eq $kScriptPage)
			{
				$loadFileName = $E_bookmarkFileName ;	# Load the bookmarked page later
				$loadFileField = $E_bookmarkFileField ;
				if ($E_writeOnNext eq 'Yes')
				{
					&WriteDataFile_2 ($E_dataFileName, 'No') ;	# Append to or update the data file
				}
				# Add to the beginning of the back filename list
				unshift (@E_backFileName, $E_reloadFileField) ;
			}
		}
		elsif ($bGoBack eq 'Yes')							# Going backward?
		{
			# Remove the first item in the back filename list
			$loadFileField = shift (@E_backFileName) ;	# Remove the first item
			$loadFileName = $raw_data{$loadFileField} ;	# Load the previous page later
		}
		elsif ($E_file eq '')
		{
			local $err = &WriteDataFile_2 ($E_dataFileName, 'Yes');	# Append to or update the data file
			if ($err == 0)
			{
				local $page = &CreateSuccessPage ;		# Generate the confirmation page
				if ($E_test & 8)
				{
					local $logPath = $E_dataFileName . &SafeEval (&ExpandShortVarRefs ($E_test8LogAddExt)) ;
					local ($lockHandle, $lockPath, $lockMode) = &LockFile ($logPath, 2);
					&AppendTextFile ($logPath, "[Output]\n" . $page . "\n\n") ;
					&UnlockFile ($lockHandle, $lockPath, $lockMode) ;
				}
				&SendToOutput ($page) ;						# Send the confirmation page
			}
			else
			{
				$loadFileName = $E_reloadFileName ;		# Reload the page later
				$loadFileField = $E_reloadFileField ;
				$bReloadingPage = 'Yes' ;					# We are reloading the page
			}
		}
		else
		{
			# Must be loading a file
			$loadFileName = $E_file	;						# Load the file specified by $E_file
			$loadFileField = $E_reloadFileField ;
		}
	}

	# --------------------------------
	# Load another page (if necessary)
	# --------------------------------
	if ($loadFileName ne '')
	{
		# ----------------------------------------
		# Step 1: Load the page file into a string
		# ----------------------------------------

		# Load the page file into a string
		local $page = &ReadTextFile ($loadFileName) ;
		local %conf_data = () ;								# Configuration file data

		# ----------------------------------------
		# Step 2: Load the configuration file data
		# ----------------------------------------

		# Maybe load the configuration file
		{
			local $conf_path = &GetStandardTagAttributeValue ($page, 'E_conf') ;
			if (defined $conf_path && $conf_path ne '')
			{
				$conf_data{'E_reloadFileName'} = $loadFileField ;
				&ReadConfFile ($conf_path, \%conf_data) ;
			}
		}

		# ----------------------------------------
		# Step 3: Load field variables from string
		# ----------------------------------------

		local $E_incWarningSubmit ;						# Include warning submit button?
		{
			$E_incWarningSubmit = (defined $conf_data{'E_incWarningSubmit'} ? $conf_data{'E_incWarningSubmit'} : &GetStandardTagAttributeValue ($page, 'E_incWarningSubmit')) ;
		}
		
		local $E_nextSubmitValue ;							# Label on next submit button
		local $E_backSubmitValue ;							# Label on back submit button
		local $E_resetSubmitValue ;						# Label on reset button
		local $E_warningSubmitValue ;						# Label on ignore warnings submit button
		local $E_bookmarkSubmitValue ;					# Label on bookmark submit button
		{
			$E_nextSubmitValue = (defined $conf_data{'E_nextSubmitValue'} ? $conf_data{'E_nextSubmitValue'} : &GetStandardTagAttributeValue ($page, 'E_nextSubmitValue')) ;
			$E_backSubmitValue = (defined $conf_data{'E_backSubmitValue'} ? $conf_data{'E_backSubmitValue'} : &GetStandardTagAttributeValue ($page, 'E_backSubmitValue')) ;
			$E_resetSubmitValue = (defined $conf_data{'E_resetSubmitValue'} ? $conf_data{'E_resetSubmitValue'} : &GetStandardTagAttributeValue ($page, 'E_resetSubmitValue')) ;
			$E_warningSubmitValue = (defined $conf_data{'E_warningSubmitValue'} ? $conf_data{'E_warningSubmitValue'} : &GetStandardTagAttributeValue ($page, 'E_warningSubmitValue')) ;
			$E_bookmarkSubmitValue = (defined $conf_data{'E_bookmarkSubmitValue'} ? $conf_data{'E_bookmarkSubmitValue'} : &GetStandardTagAttributeValue ($page, 'E_bookmarkSubmitValue')) ;
		}

		local $E_warningSubmitMessage ;					# Message describing how to submit and ignore warnings
		local $E_warningPrefix ;							# Prefix to each warning message (ex. warning:)
		local $E_errorPrefix ;								# Prefix to each error message (ex. error:)
		local $E_warningSummaryHeading ;					# Warning summary heading (appears above list of warnings)
		local $E_errorSummaryHeading ;					# Error summary heading (appears above list of errors)
		local $E_backToWarningSummary ;					# Back to warning summary links next to question text
		local $E_backToErrorSummary ;						# Back to error summary links next to question text
		{
			$E_warningSubmitMessage = (defined $conf_data{'E_warningSubmitMessage'} ? $conf_data{'E_warningSubmitMessage'} : &GetStandardTagAttributeValue ($page, 'E_warningSubmitMessage')) ;
			$E_warningPrefix = (defined $conf_data{'E_warningPrefix'} ? $conf_data{'E_warningPrefix'} : &GetStandardTagAttributeValue ($page, 'E_warningPrefix')) ;
			$E_errorPrefix = (defined $conf_data{'E_errorPrefix'} ? $conf_data{'E_errorPrefix'} : &GetStandardTagAttributeValue ($page, 'E_errorPrefix')) ;
			$E_warningSummaryHeading = (defined $conf_data{'E_warningSummaryHeading'} ? $conf_data{'E_warningSummaryHeading'} : &GetStandardTagAttributeValue ($page, 'E_warningSummaryHeading')) ;
			$E_errorSummaryHeading = (defined $conf_data{'E_errorSummaryHeading'} ? $conf_data{'E_errorSummaryHeading'} : &GetStandardTagAttributeValue ($page, 'E_errorSummaryHeading')) ;
			$E_backToWarningSummary = (defined $conf_data{'E_backToWarningSummary'} ? $conf_data{'E_backToWarningSummary'} : &GetStandardTagAttributeValue ($page, 'E_backToWarningSummary')) ;
			$E_backToErrorSummary = (defined $conf_data{'E_backToErrorSummary'} ? $conf_data{'E_backToErrorSummary'} : &GetStandardTagAttributeValue ($page, 'E_backToErrorSummary')) ;
		}

		# ------------------------------------------------
		# Step 4: Clear and renitialize arrays from string
		# ------------------------------------------------

		# Extract all variable names from non-multiple selection lists on page into @ansVarNames array
		local (@ansVarNames) = &GetTagAttributeValues ($page, 'NAME\s*=\s*"?V_[a-zA-Z_0-9]*"?[^>]*>', 'NAME\s*=\s*"?V_[a-zA-Z_0-9]*"?', 'V_[a-zA-Z_0-9]*') ;
		{
			# Extract all variable names from multiple selection lists on page into @avn array
			local (@avn) = &GetTagAttributeValues ($page, 'VALUE\s*=\s*"V_[a-zA-Z_0-9]*,[^>]*>', 'VALUE\s*=\s*"V_[a-zA-Z_0-9]*,', 'V_[a-zA-Z_0-9]*') ;
			for (local ($iii) = 0 ; $iii <= $#avn ; $iii++)
			{
				local ($varName) = $avn[$iii] ;
				push (@ansVarNames, $varName) ;			# Add variable name to @ansVarNames array
			}
		}

		# Clear and reinitialize the %ansVarValues associative array
		# %ansVarValues has all variables associated with questions on the page indexed by name
		{
			# Initialize %ansVarVales with values in %varValues from the caller
			%ansVarValues = () ;
			for (local ($iii) = 0; $iii < $#ansVarNames + 1; $iii++)
			{
				local ($varName) = substr ($ansVarNames[$iii], 2) ;
				if (defined $varValues{$varName})
				{
					$ansVarValues{$varName} = $varValues{$varName} ;
				}
			}

			# Remove variables from %ansVarValues whose values are the same in %defVarValues
			# Do this to avoid running rules on default values
			local ($key) ;
			foreach $key (keys %defVarValues)
			{
				if (defined ($ansVarValues{$key}))
				{
					if ($ansVarValues{$key} eq $defVarValues{$key})
					{
						delete ($ansVarValues{$key}) ;
					}
				}
			}

			# Remove variables from %ansVarValues whose values are empty
			# Do this to avoid running rules on empty values
			foreach $key (keys %ansVarValues)
			{
				if ($ansVarValues{$key} eq '')
				{
					delete ($ansVarValues{$key}) ;
				}
			}
		}

		# Extract query fields from loaded page and merge into %qryVarValues
		# Query fields are used to load an existing record
		{
			local (@qryNameList) = &GetTagAttributeValues ($page, '<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?Q_[^>]*>', 'Q_[a-zA-Z_0-9]*') ;
			local (@qryValueList) = &GetTagAttributeValues ($page, '<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?Q_[^>]*>', 'VALUE\s*=\s*"[^"]*"', '"[^"]*"', '[^"]+') ;
			push (@qryNameList, &ExtractKeyNames ('Q_', \%conf_data)) ;
			push (@qryValueList, &ExtractKeyValues ('Q_', \%conf_data)) ;

			# Merge query name and value pairs with %qryVarValues
			# Values in %qryVarValues take precedence
			for (local $iii = 0; $iii < $#qryNameList + 1; $iii++)
			{
				# Does the name and value exist in %qryVarValues?
				local $varName = substr ($qryNameList[$iii], 2) ;
				if (!defined ($qryVarValues {$varName}))
				{
					$qryVarValues{$varName} = &SafeEval (&TagDecodeText ($qryValueList[$iii])) ;
				}
			}
		}
				
		# Initialize the %fwdVarValues associative array
		# %fwdVarValues is used to pass variable values from page to page
		%fwdVarValues = %varValues ;

		# Remove values that are on the page
		{
			for (local $iii = 0; $iii < $#ansVarNames + 1; $iii++)
			{
				local ($varName) = substr ($ansVarNames[$iii], 2) ;
				if (defined ($fwdVarValues{$varName}))
				{
					delete ($fwdVarValues{$varName}) ;
				}
			}
		}

		# %fwdVarFixups has instructions for fixing up values that are illegal
		# Build %fwdVarFixups associative array, modifies %fwdVarValues
		local (%fwdVarFixups) = () ;
		&BuildFwdVarFixups ;

		# Initialize the @fwdVarValues array
		@fwdVarValues = () ;
		{
			for (local $iii = 0; $iii < $#varList + 1; $iii++)
			{
				local $varName = $varList[$iii] ;
				if (defined ($fwdVarValues{$varName}))
				{
					$fwdVarValues[$iii] = $fwdVarValues{$varName} ;
				}
				else
				{
					$fwdVarValues[$iii] = '' ;
				}
			}
		}

		# Extract replacement instructions from loaded page
		# Replacement instructions are used to fill in controls with default values
		{
			# Load all instruction names and values
			local (@insNameList) = &GetTagAttributeValues ($page, '<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?I_[^>]*>', 'I_[a-zA-Z_0-9]*') ;
			local (@insValueList) = &GetTagAttributeValues ($page, '<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?I_[^>]*>', 'VALUE\s*=\s*"[^"]*"', '"[^"]*"', '[^"]+') ;

			%insVarValues = () ;
			for (local $iii = 0; $iii < $#insValueList + 1; $iii++)
			{
				local ($varName) = substr ($insNameList[$iii], 2) ;
				$insVarValues{$varName} = $insValueList[$iii] ;
			}
		}

		# Clear and reinitialize the %evlVarValues associative array
		if ($bReloadingPage ne 'Yes')									# Do not calculate again if reloading
		{
			# Save %fwdVarValues
			local %saveFwdVarValues = %fwdVarValues ;

			# Fixup forwarded values that contain special characters
			&FixupFwdVarValues ;									

			# Load all calculated names and values from the page
			local (@evlNameList) = &GetTagAttributeValues ($page, '<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?A_[^>]*>', 'A_[a-zA-Z_0-9]*') ;
			local (@evlValueList) = &GetTagAttributeValues ($page, '<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?A_[^>]*>', 'VALUE\s*=\s*"[^"]*"', '"[^"]*"', '[^"]+') ;
			push (@evlNameList, &ExtractKeyNames ('A_', \%conf_data)) ;
			push (@evlValueList, &ExtractKeyValues ('A_', \%conf_data)) ;

			%evlVarValues = () ;
			for (local $iii = 0; $iii < $#evlValueList + 1; $iii++)
			{
				local $name = substr ($evlNameList[$iii], 2) ;
				local $expr = &TagDecodeText ($evlValueList[$iii]) ;
				$evlVarValues{$name} = &SafeEval (&ExpandShortVarRefs_AnsDefFwd ($expr)) ;
				if ($@)
				{
					&DieMsg ("Fatal Error", "Error in \"" . &HTMLEncodeText ($name) . "\" expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
				}
			}
			# Restore %fwdVarValues
			%fwdVarValues = %saveFwdVarValues ;
		}

		# Clear and reinitialize the %scriptExprResults associative array
		{
			# Load all script expression names and values from the page
			local (@scriptExprNameList) = &GetTagAttributeValues ($page, '<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?B_[^>]*>', 'B_[a-zA-Z_0-9]*') ;
			local (@scriptExprValueList) = &GetTagAttributeValues ($page, '<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?B_[^>]*>', 'VALUE\s*=\s*"[^"]*"', '"[^"]*"', '[^"]+') ;
			push (@scriptExprNameList, &ExtractKeyNames ('B_', \%conf_data)) ;
			push (@scriptExprValueList, &ExtractKeyValues ('B_', \%conf_data)) ;

			%scriptExprResults = () ;
			for (local $iii = 0; $iii < $#scriptExprValueList + 1; $iii++)
			{
				local $name = substr ($scriptExprNameList[$iii], 2) ;
				local $expr = &TagDecodeText ($scriptExprValueList[$iii]) ;
				$scriptExprResults{$name} = &SafeEval (&ExpandShortVarRefs ($expr)) ;
				if ($@)
				{
					&DieMsg ("Fatal Error", "Error in \"" . &HTMLEncodeText ($name) . "\" expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
				}
			}
		}

		# Clear and reinitialize the %rules associative array
		{
			# Load all rule names and values from the page
			local (@ruleNameList) = &GetTagAttributeValues ($page, '<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?R_[^>]*>', 'R_[a-zA-Z_0-9]*') ;
			local (@ruleValueList) = &GetTagAttributeValues ($page, '<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?R_[^>]*>', 'VALUE\s*=\s*"[^"]*"', '"[^"]*"', '[^"]+') ;
			push (@ruleNameList, &ExtractKeyNames ('R_', \%conf_data)) ;
			push (@ruleValueList, &ExtractKeyValues ('R_', \%conf_data)) ;

			%rules = () ;
			for (local $iii = 0; $iii < $#ruleValueList + 1; $iii++)
			{
				$rules{$ruleNameList[$iii]} = $ruleValueList[$iii] ;
			}
		}

		# Clear and reinitialize the %pageRules associative array
		{
			# Load all page rule names and values from the page
			local (@pageRuleNameList) = &GetTagAttributeValues ($page, '<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?S_[^>]*>', 'S_[a-zA-Z_0-9]*') ;
			local (@pageRuleValueList) = &GetTagAttributeValues ($page, '<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?S_[^>]*>', 'VALUE\s*=\s*"[^"]*"', '"[^"]*"', '[^"]+') ;
			push (@pageRuleNameList, &ExtractKeyNames ('S_', \%conf_data)) ;
			push (@pageRuleValueList, &ExtractKeyValues ('S_', \%conf_data)) ;

			%pageRules = () ;
			for (local $iii = 0; $iii < $#pageRuleValueList + 1; $iii++)
			{
				$pageRules{$pageRuleNameList[$iii]} = $pageRuleValueList[$iii] ;
			}
		}
		
		# Initialize the bookmark on back values in globalFields
		if ($#E_bookmarkOnBack >= 0)
		{
			$globalFields{$kg_BookmarkOnBack} = join ('|', @E_bookmarkOnBack) ;
		}
		elsif (defined ($globalFields{$kg_BookmarkOnBack}))
		{
			delete $globalFields{$kg_BookmarkOnBack} ;			# Remove field from globalFields
		}

		# ----------------------------------------------------
		# Step 5: Run the rules using the reinitialized arrays
		# ----------------------------------------------------

		# Run the rules
		if ($bReloadingPage ne 'Yes' || ($#rulWrns == 0 && $#rulErrs == 0))
		{
			%rulWrns = ();
			%rulErrs = ();
			
			if ($E_applyRule eq 'Yes' && (!defined ($globalFields{$kg_ApplyRule}) || $globalFields{$kg_ApplyRule} eq 'Yes'))	# Run the rules?
			{
				if ($bReloadingPage eq 'Yes')							# Are we reloading the page?
				{
					&RunRules ($kSaving) ;								# Run the rules on %ansVarValues
				}
				elsif (%ansVarValues)									# Are there any variables?
				{
					&RunRules ($kLoading) ;								# Run the rules on %ansVarValues
				}
			}
		}

		# -----------------------
		# Step 6: Modify the page
		# -----------------------

		# Run the page rules
		$page = &RunPageRules ($page) ;

		# Indicate the page has been loaded and modified by the script
		$page = &ReplaceStandardTagAttributeValue ($page, 'E_dataSrc', $kScriptPage) ;

		# Insert names and values from $E_varList and $E_varDefVal
		$page = &ReplaceStandardTagAttributeValue ($page, 'E_varList', $E_varList) ;
		$page = &ReplaceStandardTagAttributeValue ($page, 'E_varDefVal', $E_varDefVal) ;
		
		# Insert names and values from %fwdVarValues and %fwdVarFixups into page (if any)
		$page = &InsertFwdVarValuesAndFixups ($page) ;

		# Fixup forwarded values that contain special characters
		&FixupFwdVarValues ;									

		# Replace any existing query tags with a comment (to prevent duplicates)
		$page = &RemoveExistingQueryFields ($page) ;

		# Insert global fields from %globalFields into page (if any)
		# Call before InsertQryVarValues because it searches and replaces the same text
		$page = &InsertGlobalFields ($page) ;

		# Insert script expression results from %scriptExprResults into page (if any)
		# Call before InsertQryVarValues because it searches and replaces the same text
		$page = &InsertScriptExprResultFields ($page) ;

		# Insert check E_reloadFileName fields (Safari browser defect #8613)
		# Call before InsertQryVarValues because it searches and replaces the same text
		$page = &InsertCheckReloadFileNameFields ($page) ;

		# Insert names and values from %qryVarValues and %qryVarFixups into page (if any)
		$page = &InsertQryVarValues ($page) ;
		
		# Insert default values from %ansVarValues into page (if any)
		$page = &InsertInsVarValues ($page) ;

		# Insert warning messages into page (if any)
		$page = &InsertWarnings ($page) ;

		# Insert error messages into page (if any)
		$page = &InsertErrors ($page) ;

		# Update back file name list on page
		$page = &UpdateBackFileName ($page) ;
		
		# Insert back button into page (if applicable)
		$page = &InsertBackButton ($page) ;

		# Insert bookmark button into page (if applicable)
		$page = &InsertBookmarkButton ($page) ;

		# ---------------------------------------
		# Step 7: Send the page to the respondent
		# ---------------------------------------

		# Send the page to the respondent
		if ($E_test & 8)
		{
			local $logPath = $E_dataFileName . &SafeEval (&ExpandShortVarRefs ($E_test8LogAddExt)) ;
			local ($lockHandle, $lockPath, $lockMode) = &LockFile ($logPath, 2);
			&AppendTextFile ($logPath, "[Output]\n" . $page . "\n\n") ;
			&UnlockFile ($lockHandle, $lockPath, $lockMode) ;
		}
		&SendToOutput (&GetContentTypeHTML () . $page) ;
	}

# Subroutine ReadParse
#
# Reads in GET or POST data, converts it to unescaped text, and puts
# key/value pairs in %in, using "\0" to separate multiple selections
# Returns >0 if there was input, 0 if there was no input 
# undef indicates some failure.
#
# If no parameters are given (i.e., ReadParse returns FALSE), then a
# form could be output. If no method is given, the script will process
# both command-line arguments of the form: name=value and any text that
# is in the query string. This is intended to aid debugging and may be
# changed in future releases

sub ReadParse
{
	local ($raw_input) = '' ;
	local (@raw_input) = () ;
	local ($errflag) = '' ;
	local ($cmdflag) = '' ;

	# Disable warnings as this code deliberately uses local and environment
	# variables which are preset to undef (i.e., not explicitly initialized)

	local ($perlwarn) = $^W;
	$^W = 0;

	# Get several useful environment variables
	local ($type) = &GetServerVariable ('CONTENT_TYPE') ;
	local ($len)  = &GetServerVariable ('CONTENT_LENGTH') ;
	local ($meth) = &GetServerVariable ('REQUEST_METHOD') ;

	if (!defined $meth || $meth eq '' || $meth eq 'GET' || $type eq 'application/x-www-form-urlencoded')
	{
		local ($key, $val, $iii);

		# Read in text
		if (!defined $meth || $meth eq '')
		{
			$raw_input = &GetQueryString () ;
			$cmdflag = 1;  # also use command-line options
		}
		elsif ($meth eq 'GET' || $meth eq 'HEAD')
		{
			$raw_input = &GetQueryString () ;
		}
		elsif ($meth eq 'POST')
		{
			$errflag = &GetFormData ($len) ;
		}
		else
		{    
			&DieMsg ("Fatal Error", "The script cannot process your survey because ".
						"it does not recognize the request method " . &HTMLEncodeText ($meth) . ".",
						"Please contact this site's webmaster") ;
		}

		# Save the unparsed raw input for logging
		$unparsed_raw_data = $raw_input ;

		@raw_input = split (/[&;]/, $raw_input);
		push (@raw_input, @ARGV) if $cmdflag; # add command-line parameters

		foreach $iii (0 .. $#raw_input)
		{
			# Convert plus to space
			$raw_input[$iii] =~ s/\+/ /g;

			# Split into key and value.  
			($key, $val) = split (/=/,$raw_input[$iii],2); # splits on the first =.
			# Convert %XX from hex numbers to alphanumeric
			$key =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;
			$val =~ s/%([A-Fa-f0-9]{2})/pack("c",hex($1))/ge;

			if (substr ($key, 0, 2) eq 'M_')
         {
				# Get keys and values from value
				local (@mKeyVals) = split(/,/,$val); # splits on all , (commmas).
				if ($#mKeyVals >= 0)
				{
					for (local($jjj) = 0 ; $jjj <= $#mKeyVals ; $jjj += 2)
					{
						local ($mKey) = $mKeyVals[$jjj] ;
						local ($mVal) = $mKeyVals[$jjj + 1] ;

						$mKey =~ s/^\s+//;			# Remove beginning white space
						$mKey =~ s/\s+$//;			# Remove ending white space

						$mVal =~ s/^\s+//;			# Remove beginning white space
						$mVal =~ s/\s+$//;			# Remove ending white space

						# Associate key and value
						if (defined ($raw_data{$mKey}))
						{
							&DieMsg ("Fatal Error", "The script cannot process your survey because ".
							         "the Web survey contains multiple references to the name " . &HTMLEncodeText ($key) . ". ".
									   "Remove or rename one of the references or contact this site's webmaster.") ;
						}
						$raw_data{$mKey} .= $mVal;
					}
				}
			}
			else
			{
				# Associate key and value
				if (defined ($raw_data{$key}))
				{
					&DieMsg ("Fatal Error", "The script cannot process your survey because ".
					         "the Web survey contains multiple references to the name " . &HTMLEncodeText ($key) . ". ".
								"Remove or rename one of the references or contact this site's webmaster.") ;
				}
				$raw_data{$key} .= $val;
			}
		}
	}
	else
	{
		local ($contentType) = &GetServerVariable ('CONTENT_TYPE') ;
		&DieMsg ("Fatal Error", "The script cannot process your survey because ".
					"it does not recognize the content-type " . &HTMLEncodeText ($contentType) . ". ",
					"Please contact this site's webmaster.") ;
	}
	$^W = $perlwarn;
	return ($errflag ? undef :  scalar(@raw_input));
}

# Subroutine DieMsg
#
# Prints out an error message which contains appropriate headers and
# titles, then quits with the error message. 
#
# Parameters:
#	 If no parameters, gives a generic error message
#   Otherwise, the first parameter will be the title and the rest will 
#   be given as different paragraphs of the body

sub DieMsg
{
	local (@msg) = @_;
	local ($iii) ;
	local ($name) = '';

	if (!@msg)
	{
		$name = &ScriptUrl ();
		@msg = ("Fatal Error", "The script " . &HTMLEncodeText ($name) . " encountered the error $!.",
				  "Please contact this site's webmaster.") ;
	}
	&SendToOutput (&GetContentTypeHTML ());
	&SendToOutput ("<html>\n<head>\n<title>$msg[0]</title>\n</head>\n<body>\n") ;
	&SendToOutput ("<h1>$msg[0]</h1>\n") ;
	foreach $iii (1 .. $#msg)
	{
		&SendToOutput ("<p>$msg[$iii]</p>\n") ;
	}
	&SendToOutput ("<p><h6>v$kVersion - ".$]."</h6></p>\n") ;
	&SendToOutput ("</body>\n</html>\n") ;
	exit 1 ;
}


# Subroutine ScriptUrl
#
# Returns the URL to the script.

sub ScriptUrl
{
   return $raw_data{'E_scriptUrl'};
}

# Subroutine VarDefinedOrDie
#
# Checks if the raw data contains the passed variable name. If not, displays
# an error message and exits.

sub VarDefinedOrDie
{
	local($name) = shift(@_);
	if (!defined $raw_data{$name} )
	{
		&DieMsg ("Fatal Error",
					"The script cannot process your survey because the field " . &HTMLEncodeText ($name) . " is missing.",
					"Please contact this site's webmaster.") ;
	}
	1; #return true
}
	
# Subroutine VersionCorrectOrDie
#
# Checks whether the version of the survey matches that of
# this perl script. The version of this perl script is hard-coded in
# the code as a constant scalar, $E_version. If the version of the survey
# is different from $E_version, VersionCorrectOrDie exits with an error message.

sub VersionCorrectOrDie
{
	if ($raw_data{'E_version'} ne $E_version)
	{
		&DieMsg ("Fatal Error", "The script cannot process your survey because ".
					"the version (" . &HTMLEncodeText ($raw_data{'E_version'}) . ") and the ".
					"script's version (" . &HTMLEncodeText ($E_version) . ") are different.",
					"Please contact this site's webmaster.") ;
	}
	1; #return true
}

# Subroutine DataSrcCorrectOrDie
#
# Checks the source of the data. The data must come from a survey HTML
# page, a warning HTML page or a script. If the dta is from some other
# source, DataSrcCorrectOrDie exits with an error message.

sub DataSrcCorrectOrDie
{
	if (defined $raw_data{'E_dataSrc'} )
	{
		if (($raw_data{'E_dataSrc'} ne $kSurveyPage) && ($raw_data{'E_dataSrc'} ne $kDirect) && ($raw_data{'E_dataSrc'} ne $kScriptPage))
		{
			&DieMsg ("Fatal Error", "The script cannot process your survey because ".
						"E_dataSrc is not " . &HTMLEncodeText ($kSurveyPage) . ", " . &HTMLEncodeText ($kDirect) . " or " . &HTMLEncodeText ($kScriptPage) . ".",
						"Please contact this site's webmaster.") ;
		}
		$E_dataSrc = $raw_data{'E_dataSrc'} ;
	}
	1; #return true
}

# Subroutine CheckReloadFileName
#
# If the environment variable E_checkReloadFileName exists and has the
# value 'Yes', verifies the correctness of the E_reloadFileName
# environment variable in raw_data. If the environment variable
# E_rFN_<value> exists where <value> is the value of the
# E_reloadFileName environment variable, E_reloadFileName must be
# correct. Works around Safari browser defect #8613 where the browser
# does not update the values of input fields present in multiple pages.

sub CheckReloadFileName
{
	if (defined $raw_data{'E_reloadFileName'} && defined $raw_data{'E_checkReloadFileName'} && $raw_data{'E_checkReloadFileName'} eq 'Yes')
	{
		local $reloadFileName = $raw_data{'E_reloadFileName'} ;
		local $E_rFN = 'E_rFN_' . $reloadFileName ;
		if (!defined $raw_data{$E_rFN} || $raw_data{$E_rFN} ne $reloadFileName)
		{
			&DieMsg ("Fatal Error",
						"The script cannot process your survey because the browser sent unexpected data for E_reloadFileName. The unexpected data was \"" . &HTMLEncodeText ($reloadFileName) . "\". If you are using Safari, this may be due to a defect in the browser.",
						"Please click on your browser's Back button, then click on your browser's Reload button and try again. If this error appears again, close your browser and try a different browser or contact this site's webmaster.") ;
		}
	}
	1; #return true
}

# Subroutine ApplyRuleCorrectOrDie
#
# Checks whether environment variable E_ApplyRule exists in raw_data. 
# If it does exist, $E_applyRule is set to the value in E_ApplyRule,
# and then the subroutine checks whether the value of $E_applyRule is Yes or No. 
# When $E_applyRule is neither 'Yes' nor 'No', the subroutine exits with an error
# message.       

sub ApplyRuleCorrectOrDie
{
	if (defined $raw_data{'E_applyRule'} )
	{
		$E_applyRule = $raw_data{'E_applyRule'} ;
		if ($E_applyRule ne 'Yes' && $E_applyRule ne 'No' )
		{
			&DieMsg("Fatal Error", "The script cannot process your survey because ".
					  "E_applyRule is neither Yes nor No.",
					  "Please contact this site's webmaster.") ;
		}
	}
	1; #return true
}

# Subroutine AllowNoResponseCorrectOrDie
#
# Checks whether environment variable E_allowNoResponse exists in raw_data. 
# If it does exist, $E_allowNoResponse is set to the value in E_allowNoResponse,
# and then the subroutine checks whether the value of $E_allowNoResponse is Yes or No. 
# When $E_allowNoResponse is neither 'Yes' nor 'No', the subroutine exits with an error
# message.       

sub AllowNoResponseCorrectOrDie
{
	if (defined $raw_data{'E_allowNoResponse'} )
	{
		$E_allowNoResponse = $raw_data{'E_allowNoResponse'} ;
		if ($E_allowNoResponse ne 'Yes' && $E_allowNoResponse ne 'No' )
		{
			&DieMsg("Fatal Error", "The script cannot process your survey because ".
					  "E_allowNoResponse is neither Yes nor No.",
					  "Please contact this site's webmaster.") ;
		}
	}
	1; #return true
}

# Subroutine GetRawDataFieldValue
#
# Checks if given environment variable exists in raw_data. 
# If it does exist, returns the value. Otherwise returns ''.

sub GetRawDataFieldValue
{
	local ($name) = $_[0] ;
	local ($defv) = $_[1] ;
	local ($value) = '' ;

	if (defined $raw_data{$name} )
	{
		$value = $raw_data{$name} ;
	}
	else
	{
		$value = $defv ;
	}
	return $value ;
}

# Subroutine EvalRawDataFieldValue
#
# Checks if given environment variable exists in raw_data. 
# If it does exist, evaluates the value. Otherwise returns ''.

sub EvalRawDataFieldValue
{
	local $name = $_[0] ;
	local $defv = $_[1] ;
	local $value = '' ;

	if (defined $raw_data{$name} )
	{
		local $expr = $raw_data{$name} ;
		$value = &SafeEval ($expr) ;
		if ($@)
		{
			&DieMsg ("Fatal Error", "Error in \"" . &HTMLEncodeText ($name) . "\" expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
		}
	}
	else
	{
		$value = $defv ;
	}
	return $value ;
}

# Subroutine AddPrefixToFields
#
# When a field of the form PF_NAM=PREFIX is included in raw_data,
# creates a new PREFIX_NAM field in raw_data having a copy of the NAM
# field's data. For example, having the field PF_PID=V_ causes the
# data for field PID to be copied to the new field V_PID.

sub AddPrefixToFields
{
	local $key ;
	foreach $key (keys %raw_data)
	{
		local $label = substr ($key, 0, 3) ;
		if ($label eq 'PF_' && $key ne 'PF_')
		{
			local $name = substr ($key, 3) ;							# Extract the field name
			if (defined ($raw_data{$name}))
			{
				local $prefix = $raw_data{$key} ;					# Get the prefix
				$raw_data{$prefix.$name} = $raw_data{$name} ;	# Copy the value
			}
		}
	}
}

# Subroutine DoUserCommands
#
# Extracts and processes command scripts from %raw_data.

sub DoUserCommands
{
	local $prefix = $_[0] ;
	local $key ;
	foreach $key (keys %raw_data)
	{
		local $label = substr ($key, 0, length ($prefix)) ;
		if ($label eq $prefix && $key ne $prefix)
		{
			local $line = $raw_data{$key} ;		# Extract the command line

			local (@cmd) = split (/,/, $line) ;
			if ($cmd[0] eq '1')						# Type 1: value="1,expr,name,value" - if expr evaluates to 1, assigns value to $raw_data{name}
			{
				local $expr = &TagDecodeText ($cmd[1]) ;										# Get the expression
				local $result = &SafeEval (&ExpandShortVarRefs ($expr)) ;				# Evaluate the expression
				if ($@)
				{
					&DieMsg ("Fatal Error", "Error in command expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
				}
				$raw_data{$cmd[2]} = &TagDecodeText ($cmd[3]) if ($result eq '1') ;	# Assign the value to $raw_data{name} if expr evaluates to 1
			}
			elsif ($cmd[0] eq '2')					# Type 2: value="2,expr1,name,expr2" - if expr1 evaluates to 1, assigns the result of evaluating expr2 to $raw_data{name}
			{
				local $expr = &TagDecodeText ($cmd[1]) ;										# Get expression 1
				local $result = &SafeEval (&ExpandShortVarRefs ($expr)) ;				# Evaluate the expression
				if ($@)
				{
					&DieMsg ("Fatal Error", "Error in command expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
				}

				if ($result eq '1')																	# Assign the result of evaluating expr2 to $raw_data{name}?
				{
					$expr = &TagDecodeText ($cmd[3]) ;											# Get expression 2
					$raw_data{$cmd[2]} = &SafeEval (&ExpandShortVarRefs ($expr)) ;		# Assign the result of evaluating expr2 to $raw_data{name}
					if ($@)
					{
						&DieMsg ("Fatal Error", "Error in command expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
					}
				}
			}
			elsif ($cmd[0] eq '3')					# Type 3: value="3,expr1,name,expr2" - if expr1 evaluates to 1, assigns the result of evaluating expr2 to $varValues{name}
			{
				local $expr = &TagDecodeText ($cmd[1]) ;										# Get expression 1
				local $result = &SafeEval (&ExpandShortVarRefs ($expr)) ;				# Evaluate the expression
				if ($@)
				{
					&DieMsg ("Fatal Error", "Error in command expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
				}

				if ($result eq '1')																	# Assign the result of evaluating expr2 to $varValues{name}?
				{
					$expr = &TagDecodeText ($cmd[3]) ;											# Get expression 2
					$result = &SafeEval (&ExpandShortVarRefs ($expr)) ;					# Assign the result of evaluating expr2 to $varValues{name}
					if ($@)
					{
						&DieMsg ("Fatal Error", "Error in command expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
					}
					else
					{
						local $name = $cmd[2] ;														# Get the name of the variable
						local $pos = &GetVarListPos ($name) ;									# Get the position of the variable in the varList array
						if ($pos >= 0)
						{
							$varValues{$name} = $result ;											# Assign the result to $varValues{name}
							$varValues[$pos] = $result ;											# Assign the result to $varValues[pos]

							# Does the variable have a question on this page?
							if (defined ($ansVarValues{$name}) || (defined ($insVarValues{$name})))
							{
								$ansVarValues{$name} = $result;									# Assign the result to $ansVarValues{name} in case a rule references the variable
							}
							else
							{
								$fwdVarValues{$name} = $result;									# Assign the result to $fwdVarValues{name}
							}
						}
					}
				}
			}
			elsif ($cmd[0] eq '4')					# Type 4: value="4,expr1,name,expr2" - if expr1 evaluates to 1, assigns the result of evaluating expr2 to $globalFields{name}
			{
				local $expr = &TagDecodeText ($cmd[1]) ;										# Get expression 1
				local $result = &SafeEval (&ExpandShortVarRefs ($expr)) ;				# Evaluate the expression
				if ($@)
				{
					&DieMsg ("Fatal Error", "Error in command expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
				}

				if ($result eq '1')																	# Assign the result of evaluating expr2 to $globalFields{name}?
				{
					$expr = &TagDecodeText ($cmd[3]) ;											# Get expression 2
					$globalFields{$cmd[2]} = &SafeEval (&ExpandShortVarRefs ($expr)) ;		# Assign the result of evaluating expr2 to $globalFields{name}
					if ($@)
					{
						&DieMsg ("Fatal Error", "Error in command expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
					}
				}
			}
			elsif ($cmd[0] eq '5')					# Type 5: value="5,expr,numOfVars,name1,name2,..." - if expr evaluates to 1, clears $varValues{name1}, $varValues{name2},...
			{
				local $expr = &TagDecodeText ($cmd[1]) ;										# Get expression
				local $result = &SafeEval (&ExpandShortVarRefs ($expr)) ;				# Evaluate the expression
				if ($@)
				{
					&DieMsg ("Fatal Error", "Error in command expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
				}

				if ($result eq '1')																	# Clear $varValues{name1}, $varValues{name2},...?
				{
					local $numOfVars = $cmd[2] ;													# Get the number variables

					for (local $iii = 0; $iii < $numOfVars; $iii++)
					{
						local $name = $cmd[3 + $iii] ;											# Get the name of the variable
						local $pos = &GetVarListPos ($name) ;									# Get the position of the variable in the varList array
						if ($pos >= 0)
						{
							delete ($varValues{$name}) ;											# Clear $varValues{name}
							$varValues[$pos] = '' ;													# Clear $varValues[pos]

							# Does the variable have a question on this page?
							if (defined ($ansVarValues{$name}) || (defined ($insVarValues{$name})))
							{
								delete ($ansVarValues{$name}) ;									# Clear $ansVarValues{name} in case a rule references the variable
							}
							else
							{
								delete ($fwdVarValues{$name}) ;									# Clear $fwdVarValues{name}
							}
						}
					}
				}
			}
		}
	}
	1 ; #return true
}

# Subroutine GetNextFileName
#
# Checks whether environment variable E_nextFileName exists in raw_data. 
# If it does exist, $E_nextFileName is set to the value in E_nextFileName.

sub GetNextFileName
{
	if (defined $raw_data{'E_nextFileName'} )
	{
		local $expr = &TagDecodeText ($raw_data{'E_nextFileName'}) ;
		$E_nextFileField = &SafeEval (&ExpandShortVarRefs ($expr)) ;
		if ($@)
		{
			&DieMsg ("Fatal Error", "Error in \"E_nextFileName\" expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
		}

		if (defined ($raw_data{$E_nextFileField}))
		{
			$E_nextFileName = $raw_data{$E_nextFileField} ;
		}
		else
		{
			$E_nextFileName = '' ;
		}
	}
	1; #return true
}

# Subroutine GetReloadFileName
#
# Checks whether environment variable E_reloadFileName exists in raw_data. 
# If it does exist, $E_reloadFileName is set to the value in
# E_reloadFileName.

sub GetReloadFileName
{
	if (defined $raw_data{'E_reloadFileName'} )
	{
		$E_reloadFileField = $raw_data{'E_reloadFileName'} ;

		if (defined ($raw_data{$E_reloadFileField}))
		{
			$E_reloadFileName = $raw_data{$E_reloadFileField} ;
		}
		else
		{
			$E_reloadFileName = '' ;
		}
	}
	1; #return true
}

# Subroutine GetBackFileName
#
# Checks whether environment variable E_backFileName exists in raw_data. 
# If it does exist, @E_backFileName is set to the values in
# E_backFileName.

sub GetBackFileName
{
	if (defined $raw_data{'E_backFileName'} )
	{
		local $fields = $raw_data{'E_backFileName'} ;
		if ($fields ne '')
		{
			@E_backFileName = split (/\|/, $fields) ;	# split into an array of fields
		}
	}
	1; #return true
}

# Subroutine GetBookmarkOnBack
#
# Checks whether global field $kg_BookmarkOnBack exists in globalFields. 
# If it does exist, @E_bookmarkOnBack is set to the values in
# $globalFields{$kg_BookmarkOnBack}.

sub GetBookmarkOnBack
{
	if (defined $globalFields{$kg_BookmarkOnBack} )
	{
		local $values = $globalFields{$kg_BookmarkOnBack} ;
		if ($values ne '')
		{
			@E_bookmarkOnBack = split (/\|/, $values) ;	# split into an array of values
		}
	}
	1; #return true
}

# Subroutine MaybeSkipNextPage
#
# Loads the file path specified by the second parameter and tests
# to determine if the file should be skipped. If so, loads and
# tests the next filename, continuing until it finds a file that
# does not want to be skipped. Returns the final file field and
# file path pair.

sub MaybeSkipNextPage
{
	local $fileField = $_[0] ;
	local $filePath = $_[1] ;
	local $save_E_reloadFileName = $raw_data{'E_reloadFileName'} ;					# Save $raw_data{'E_reloadFileName'}

	while ($filePath ne '')
	{
		local $bAgain = 'No' ;
		local $page = &ReadTextFile ($filePath) ;			# Load the page into a string
		local (@tests) = &GetTagAttributeValues ($page, '<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?K_[^>]*>', 'VALUE\s*=\s*"[^"]*"', '"[^"]*"', '[^"]+') ;
		local %conf_data = () ;									# Configuration file data

		$raw_data{'E_reloadFileName'} = $fileField ;		# E_nextFileName expressions may use $raw_data{'E_reloadFileName'}

		# Maybe load the configuration file
		{
			local $conf_path = &GetStandardTagAttributeValue ($page, 'E_conf') ;
			if (defined $conf_path && $conf_path ne '')
			{
				$conf_data{'E_reloadFileName'} = $fileField ;
				&ReadConfFile ($conf_path, \%conf_data) ;
			}
		}
		push (@tests, &ExtractKeyValues ('K_', \%conf_data)) ;

		if ($#tests >= 0)											# Any tests on the page?
		{
			local $bStop = 'No' ;
			for (local $iii = 0; $iii < $#tests + 1; $iii++)
			{
				local (@test) = split (/,/, $tests[$iii]) ;
				if ($test[0] eq '1')								# Type 1: value="1,expr" - uses E_nextFileName expression to determine next page if test fails
				{
					local $expr = &TagDecodeText ($test[1]) ;								# Get the expression
					local $result = &SafeEval (&ExpandShortVarRefs ($expr)) ;		# Evaluate the expression
					if ($@)
					{
						&DieMsg ("Fatal Error", "Error in skip rule expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
					}

					if ($result ne '1')							# Skip this page?
					{
						# Get the expression that determines the next page from E_nextFileName
						$expr = &TagDecodeText ((defined $conf_data{'E_nextFileName'} ? $conf_data{'E_nextFileName'} : &GetStandardTagAttributeValue ($page, 'E_nextFileName'))) ;
						$fileField = &SafeEval (&ExpandShortVarRefs ($expr)) ;		# Evaluate the expression
						if ($@)
						{
							&DieMsg ("Fatal Error", "Error in skip rule expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
						}
						# Get the path from the E_fileName_* field
						$filePath = (defined $conf_data{$fileField} ? $conf_data{$fileField} : &GetStandardTagAttributeValue ($page, $fileField)) ;
						$bStop = 'Yes' ;							# Stop evaluating expressions on this page
						$bAgain = 'Yes' ;							# Loop again with new page
					}
				}
				elsif ($test[0] eq '2')							# Type 2: value="2,expr1,expr2" - uses expr2 expression to determine next page if test fails
				{
					local $expr = &TagDecodeText ($test[1]) ;								# Get the first expression
					local $result = &SafeEval (&ExpandShortVarRefs ($expr)) ;		# Evaluate the expression
					if ($@)
					{
						&DieMsg ("Fatal Error", "Error in skip rule expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
					}

					if ($result ne '1')							# Skip this page?
					{
						$expr = &TagDecodeText ($test[2]) ;									# Get the expression that determines the next page
						$fileField = &SafeEval (&ExpandShortVarRefs ($expr)) ;		# Evaluate the expression
						if ($@)
						{
							&DieMsg ("Fatal Error", "Error in skip rule expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
						}
						# Get the path from the E_fileName_* field
						$filePath = (defined $conf_data{$fileField} ? $conf_data{$fileField} : &GetStandardTagAttributeValue ($page, $fileField)) ;
						$bStop = 'Yes' ;							# Stop evaluating expressions on this page
						$bAgain = 'Yes' ;							# Loop again with new page
					}
				}
				last if $bStop eq 'Yes' ;
			}
		}
		last if $bAgain ne 'Yes' ;
	}

	$raw_data{'E_reloadFileName'} = $save_E_reloadFileName ;							# Restore $raw_data{'E_reloadFileName'}
	
	return ($fileField, $filePath) ;
}

# Subroutine GetDefVarValues
#
# Extracts data from strings E_varList and E_varDefVal and constructs one
# regular array and one associative array. The regular array stores variable
# names in the the same order as in the string E_varList, and the associative
# array will store variable names as keys and their corresponding values in
# value fields. 

sub GetDefVarValues
{
	local ($varList) = $_[0] ;
	local ($varDefVal) = $_[1] ;

	$varList =~ tr/ //d ;

	# split into an array of variables names
	@varList = split (/,/, $varList) ;

	if ($#varList < 0)
	{
		&DieMsg ("Fatal Error", "The script cannot process your survey because ".
				   "the Web survey's hidden field E_varList contains no variables.",
				   "Please contact this site's webmaster.") ;
	}

	$_ = $varDefVal ;
	local $numOfVar = tr/,/,/ ;			# Count the number of commas
	$numOfVar += 1 ;							# The number of variables is the number of commas plus one.

	local (@varDefVal) = split (/,/, $varDefVal, $numOfVar) ;

	if ($#varList != $#varDefVal && ($#varList != 0 || $#varDefVal >= 0))
	{
		&DieMsg ("Fatal Error", "The script cannot process your survey because ".
				   "the Web survey's hidden fields E_varList (" . &HTMLEncodeText ($E_varList) . ") and E_varDefVal (" . &HTMLEncodeText ($E_varDefVal) . ") contain ".
				   "a different number of variables.",
				   "Please contact this site's webmaster.") ;
	}

	# push variable name and value pairs into %defVarValues
	for (local $iii = 0 ; $iii <= $#varList ; $iii++)
	{
		if ($iii > $#varDefVal)
		{
			$defVarValues{$varList[$iii]} = '';
		}
		else
		{
			$defVarValues{$varList[$iii]} = $varDefVal[$iii] ;
		}
	}
	1 ; #return true
}

# Subroutine GetGlobalFields
#
# Extracts global field values from %raw_data. Stores the results in
# %globalFields.
#
# In %globalFields, key stores index

sub GetGlobalFields
{
	local ($key) ;
	foreach $key (keys %raw_data)
	{
		local ($label) = substr ($key, 0, 2) ;
		if ($label eq 'G_' && $key ne 'G_')
		{
			local ($name) = substr ($key, 2) ;	# Extract field name
			$name =~ tr/ //d ;						# $name contains index
			$globalFields{$name} = $raw_data{$key} ;
		}
	}
	1 ; #return true
}

# Subroutine GetEvlGlbFields
#
# Extracts and evaluates global field values from %raw_data.
# Stores the results in %globalFields.
#
# In %globalFields, key stores index

sub GetEvlGlbFields
{
	local $key ;
	foreach $key (keys %raw_data)
	{
		local $label = substr ($key, 0, 2) ;
		if ($label eq 'F_' && $key ne 'F_')
		{
			local $name = substr ($key, 2) ;	# Extract field name
			local $expr = $raw_data{$key} ;	# Extract expression
			$name =~ tr/ //d ;					# $name contains index
			$globalFields{$name} = &SafeEval ($expr) ;
			if ($@)
			{
				&DieMsg ("Fatal Error", "Error in \"" . &HTMLEncodeText ($name) . "\" expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
			}
		}
	}
	1 ; #return true
}

# Subroutine GetAnsVarValues
#
# Extracts variable values for answered questions from $raw_data and puts into           
# associative arrays %ansVarValues. 

sub GetAnsVarValues
{
	local ($name, $label, $key); 

	foreach $key (keys %raw_data)
	{
		$label = substr ($key, 0, 2) ;
		if ($label eq 'V_' && $key ne 'V_')
		{
			$name = substr ($key, 2) ;
			$name =~ tr/ //d ;
			local ($value) = $raw_data{$key} ;

			$value =~ s/\r\n/ /g ;		# Replace carriage return/linefeed with space
			$value =~ s/\r/ /g ;			# Replace carriage return with space
			$value =~ s/\n/ /g ;			# Replace linefeed with space
			$value =~ s/\t/ /g ;			# Replace tab with space
			$value =~ s/\f/ /g ;			# Replace formfeed with space
			if ($value ne '')
			{
				$ansVarValues{$name} = $value ;
			}
		}
	}          
	foreach $key (keys %raw_data)
	{
		$label = substr ($key, 0, 2) ;
		if ($label eq 'D_' && $key ne 'D_')
		{
			$name = substr ($key, 2) ;
			$name =~ tr/ //d ;
			local ($value) = $raw_data{$key} ;

			$value =~ s/\r\n/ /g ;		# Replace carriage return/linefeed with space
			$value =~ s/\r/ /g ;			# Replace carriage return with space
			$value =~ s/\n/ /g ;			# Replace linefeed with space
			$value =~ s/\t/ /g ;			# Replace tab with space
			$value =~ s/\f/ /g ;			# Replace formfeed with space
			if ($value ne '' && !defined $ansVarValues{$name})
			{
				$ansVarValues{$name} = $value ;
			}
		}
	}          

	local (@keys) = keys %ansVarValues ;
	if ($#keys < 0 && $E_allowNoResponse eq 'No')					# No data is entered in the survey.
	{
		&DieMsg("Error", "Please respond to the survey before submitting it.",
		        "Use your browser's Back button to return to the survey ".
				  "and respond to the questions. Then click the Submit button on the ".
				  "survey again.") ;
	}
	1 ; #return true
}

# Subroutine GetFwdVarValues
#
# Extracts forwarded variable values from $raw_data and puts into the associative array %fwdVarValues.

sub GetFwdVarValues
{
	local ($varList) = $_[0] ;
	local ($varFwdVal) = $_[1] ;

	$varList =~ tr/ //d ;

	# split into an array of variables names
	@varList = split (/,/, $varList) ;

	if ($#varList < 0)
	{
		&DieMsg ("Fatal Error", "The script cannot process your survey because ".
					"the Web survey's hidden field E_varList contains no variables.",
					"Please contact this site's webmaster.") ;
	}

	$_ = $varFwdVal ;
	local $numOfVar = tr/,/,/ ;			# Count the number of commas
	$numOfVar += 1 ;							# The number of variables is the number of commas plus one.

	local (@varFwdVal) = split (/,/, $varFwdVal, $numOfVar) ;

	if ($#varList != $#varFwdVal && ($#varList != 0 || $#varFwdVal >= 0))
	{
		&DieMsg ("Fatal Error", "The script cannot process your survey because ".
					"the Web survey's hidden fields E_varList (" . &HTMLEncodeText ($E_varList) . ") and E_varFwdVal (" . &HTMLEncodeText ($E_varFwdVal) . ") contain ".
					"a different number of variables.",
					"Please contact this site's webmaster.") ;
	}

	# push variable name and value pairs into %fwdVarValues
	for (local $iii = 0 ; $iii <= $#varList ; $iii++)
	{
		if ($iii > $#varFwdVal)
		{
			$fwdVarValues{$varList[$iii]} = '';
		}
		else
		{
			$fwdVarValues{$varList[$iii]} = $varFwdVal[$iii] ;
		}
	}
	1 ; #return true
}

# Subroutine BuildFwdVarFixups
#
# Builds associative array %fwdVarFixups given the %fwdVarValues associative array
# and a set of rules.  For example, if a value in %fwdVarValues contains the double
# quote character, a corresponding fixup pair (',0) may be added to the %fwdVarFixups 
# associative array and the value in %fwdVarValues is modified to remove the
# double quote character.

sub BuildFwdVarFixups
{
	local($key);															# For looping
	local($special) = '"|<|>|,' ;										# Special character(s)
	local(@specialLst) = split(/\|/, $special) ;					# List of special characters
	local($specialCnt) = $#specialLst + 1 ;						# Number of special characters
	local($lastDitch) = "'|[|]|;" ;									# Last ditch replacement character(s)
	local(@lastDitchLst) = split(/\|/, $lastDitch) ;				# List of last ditch replacement character(s)

	foreach $key (keys %fwdVarValues)								# Check for special characters
	{
		local(@repLst) = ('0' .. '9', 'a'.. 'z', 'A' .. 'Z');	# Candidate replacement characters
		local($repCnt) = $#repLst + 1 ;								# Number of candidate replacement characters
		local($value) = $fwdVarValues{$key}	;						# Get the variable value
		for (local($iii) = 0; $iii < $specialCnt ; $iii++)		# Search for special characters
		{
			local($specialChr) = $specialLst[$iii] ;				# The special character to search for
			$_ = $value ;
			local($cntChr) = s/$specialChr/$specialChr/eg ;		# Count the number of occurrences
			if ($cntChr > 0)												# More than zero?
			{
				local($jjj) = 0 ;
				REPLOOP: for ($jjj = 0; $jjj < $repCnt; $jjj++)	# Find a replacement character
				{
					local($repChr) = $repLst[$jjj] ;					# Search for this possible replacement character
					if ($repChr ne "Used")								# Has this character already been used?
					{
						$_ = $value ;
						local($cntRepChr) = s/$repChr/$repChr/eg ;# Count the number of occurrences
						if ($cntRepChr == 0)								# No occurrences?
						{
							$fwdVarFixups{$key} .= "|" if (defined ($fwdVarFixups{$key})) ;
							$fwdVarFixups{$key} .= $repChr."|".$iii ;
							$value =~ s/$specialChr/$repChr/eg ;	# Replace the special character
							$repLst[$jjj] = "Used" ;					# Mark this one used for this value
							last REPLOOP ;									# Exit loop
						}
					}
				}
				if ($jjj == $repCnt)
				{
					$value =~ s/$specialChr/$lastDitchLst[$iii]/eg ; # Last ditch replacement
				}
			}
		}
		$fwdVarValues{$key} = $value ;								# Reassign the possibly modified value
	}
	1 ; #return true
}

# Subroutine GetFwdVarFixups
#
# Extracts variable fixup values pairs for answered questions from %raw_data 
# and puts the pairs into the associative array %fwdVarFixups.

sub GetFwdVarFixups
{
	local ($key); 

	foreach $key (keys %raw_data)
	{
		local ($label) = substr ($key, 0, 2) ;
		if ($label eq 'X_' && $key ne 'X_')
		{
			local ($name) = substr ($key, 2) ;
			$name =~ tr/ //d ;
			local ($value) = $raw_data{$key} ;
			if ($value ne '')
			{
				$fwdVarFixups{$name} = $value ;
			}
		}
	}          
	1 ; #return true
}

# Subroutine FixupFwdVarValues
#
# Replaces characters in %fwdVarValues using %fwdVarFixups for the specification
# for which characters to replace and with what characters.

sub FixupFwdVarValues
{
	local($special) = '"|<|>|,' ;								# Special character(s)
	local(@specialLst) = split(/\|/, $special) ;			# List of special characters
	local($specialCnt) = $#specialLst + 1 ;				# Number of special characters
	local($name, $key); 

	foreach $key (keys %fwdVarFixups)
	{
		if (defined ($fwdVarValues{$key}))					# Is the variable defined?
		{
			local($value) = $fwdVarValues{$key} ;			# The value before fixup
			local(@repLst) = split (/\|/, $fwdVarFixups{$key}) ;	# A list of fixup pairs
			local($repCnt) = int (($#repLst + 1) / 2) ;	# The number of fixup pairs

			for (local($iii) = 0; $iii < $repCnt ; $iii++)
			{
				local($pat) = shift @repLst ;					# The character to replace
				local($rplno) = shift @repLst ;				# The replacement character offset
				local($rpl) = $specialLst[$rplno] ;			# The replacement character

				$value =~ s/$pat/$rpl/eg ;						# Replace the character(s)
			}

			$fwdVarValues{$key} = $value ;					# Reassign the value with the fixup
		}
	}          
	1 ; #return true
}

# Subroutine GetEvlVarValues
#
# Extracts scripts from %raw_data. Stores the results of evaluating the scripts in
# %evlVarValues.
#
# In %evlVarValues, key stores index while value stores the resulting evaluation.

sub GetEvlVarValues
{
	local $key ;
	foreach $key (keys %raw_data)
	{
		local $label = substr ($key, 0, 2) ;
		if ($label eq 'A_' && $key ne 'A_')
		{
			local $name = substr ($key, 2) ;	# Extract variable name
			local $expr = &TagDecodeText ($raw_data{$key}) ;	# Extract expression

			$name =~ tr/ //d ;					# $name contains index
			$evlVarValues{$name} = &SafeEval (&ExpandShortVarRefs_AnsDefFwd ($expr)) ;
			if ($@)
			{
				&DieMsg ("Fatal Error", "Error in \"" . &HTMLEncodeText ($name) . "\" expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
			}
		}
	}
	1 ; #return true
}

# Subroutine GetInsVarValues
#
# Extracts instruction values from %raw_data. Stores the results in %insVarValues.
#
# In %insVarValues, key stores index

sub GetInsVarValues
{
	local ($key) ;
	foreach $key (keys %raw_data)
	{
		local ($label) = substr ($key, 0, 2) ;
		if ($label eq 'I_' && $key ne 'I_')
		{
			local ($name) = substr ($key, 2) ;	# Extract variable name
			$name =~ tr/ //d ;						# $name contains index
			$insVarValues{$name} = $raw_data{$key} ;
		}
	}
	1 ; #return true
}

# Subroutine GetPreQryVarValues
#
# Extracts query variable values to preprocess from %raw_data. Stores the corresponding values from
# %ansVarValues in %qryVarValues. Uses %raw_data, %ansVarValues,
# %fwdVarValues, %insVarValues and %defVarValues.

sub GetPreQryVarValues
{
	local ($result) = '' ;
	local ($key) ;
	local (@names) = () ;
	local (@values) = () ;
	local ($nCnt) = 0 ;
	local ($bComplete) = 'true' ;

	foreach $key (keys %raw_data)
	{
		local ($label) = substr ($key, 0, 2) ;
		if ($label eq 'P_' && $key ne 'P_')
		{
			local ($name) = substr ($key, 2) ;						# Extract variable name
			$name =~ tr/ //d ;											# $name contains index

			$names[$nCnt] = $name ;										# Remember the name

			# Does the variable have a question on this page?
			if (defined ($ansVarValues{$name}) || (defined ($insVarValues{$name})))
			{
				# The variable has a question on this page
				if (defined ($ansVarValues{$name}))
				{
					# The respondent answered the question
					$values[$nCnt++] = $ansVarValues{$name} ;		# Remember the answer
				}
				elsif (defined ($defVarValues{$name}))
				{
					# The respondent did not answer the question
					$values[$nCnt++] = $defVarValues{$name} ;		# Get the default value
				}
				else
				{
					# The respondent did not answer the question
					$values[$nCnt++] = '' ;								# There is no default value
				}
			}
			elsif (defined ($evlVarValues{$name}))
			{
				# The variable was automatically calculated on this page
				$values[$nCnt++] = $evlVarValues{$name} ;			# Get the default value
			}
			elsif ((defined ($fwdVarValues{$name})) && (defined ($defVarValues{$name})) && ($fwdVarValues{$name} ne $defVarValues{$name}))
			{
				# The respondent answered the question on another page
				$values[$nCnt++] = $fwdVarValues{$name} ;			# Remember the answer
			}
			elsif (defined ($qryVarValues{$name}))
			{
				;
			}
			else
			{
				$bComplete = 'false' ;									# There is no value for this variable
			}
		}
		last if ($bComplete eq 'false') ;
	}

	# Only add these variables and values to the %qryVarValues
	# associative array if all of the variables have values
	if ($nCnt > 0 && $bComplete eq 'true')
	{
		local $nEmptyCnt = 0 ;
		{
			for (local $iii = 0; $iii < $nCnt; $iii++)
			{
				$nEmptyCnt++ if (!defined ($values[$iii]) || $values[$iii] eq '') ;
			}
		}
		if ($nEmptyCnt < $nCnt)
		{
			for (local ($iii) = 0; $iii < $nCnt; $iii++)
			{
				local ($name) = $names[$iii] ;						# Get the name
				local ($value) = $values[$iii] ;						# Get the value

				if ((uc $qryVarValues{$name}) ne (uc $value))
				{
					$result = 'changed' ;								# The query has changed
				}
				$qryVarValues{$name} = $value ;						# Override the value in %qryVarValues
			}

			if ($E_recIDVar ne '' && defined ($qryVarValues{$E_recIDVar}))
			{
				delete ($qryVarValues{$E_recIDVar}) ;				# Remove record id
			}
		}
	}
	return $result;
}

# Subroutine GetQryVarValues
#
# Extracts query variable values from %raw_data. Stores the results in %qryVarValues.
#
# In %qryVarValues, key stores index. Returns the number of query
# variables found.

sub GetQryVarValues
{
	local ($cnt) = 0 ;
	local ($key) ;
	foreach $key (keys %raw_data)
	{
		local ($label) = substr ($key, 0, 2) ;
		if ($label eq 'Q_' && $key ne 'Q_')
		{
			local ($name) = substr ($key, 2) ;	# Extract variable name
			$name =~ tr/ //d ;						# $name contains index
			$qryVarValues{$name} = &SafeEval (&TagDecodeText ($raw_data{$key})) ;
			# Do not stop if evaluation results in an error
			# To display a message, add to warning or error list
			$cnt++ ;
		}
	}
	return $cnt ;
}

# Subroutine GetQryVarUTests
#
# Extracts user-defined query variable tests from %raw_data.
# Stores the results in %qryVarUTests.
#
# In %qryVarUTests, key stores index. Returns the number of query
# variables found.

sub GetQryVarUTests
{
	local ($cnt) = 0 ;
	local ($key) ;
	foreach $key (keys %raw_data)
	{
		local ($label) = substr ($key, 0, 2) ;
		if ($label eq 'T_' && $key ne 'T_')
		{
			local ($name) = substr ($key, 2) ;	# Extract variable name
			$name =~ tr/ //d ;						# $name contains index
			$qryVarUTests{$name} = $raw_data{$key} ;
			$cnt++ ;
		}
	}
	return $cnt ;
}

# Subroutine GetRecVarValues
#
# Searches for an existing record in the data file given the values in
# %qryVarValues. If found, stores the variable and value pairs in
# %recVarValues.

sub GetRecVarValues
{
	my $path = $_[0] ;
	my $idxPath = ($E_useIndexFile eq 'Yes' ? $path . &SafeEval (&ExpandShortVarRefs ($E_indexFileExt)) : $path) ;
	my (@qryVarValueKeys) = keys %qryVarValues ;
	my (@qryVarUTestKeys) = keys %qvyVarUTests ;

	return &GetRecVarValues2 ($path) if ($path ne '' && $#qryVarValueKeys >= 0 && $#qryVarUTestKeys < 0 && $E_matchEmpty ne 'Yes' && $E_recIDVar ne '' && !defined $qryVarValues{$E_recIDVar} && $E_useIndexFile eq 'Yes') ;
	return &GetRecVarValues1 ($path) if ($path ne '' && $#qryVarValueKeys >= 0) ;
	return 'false' ;
}

# Subroutine GetRecVarValues1
#
# Searches for an existing record in the data file given the values in
# %qryVarValues. If found, stores the variable name and value pairs in
# %recVarValues.

sub GetRecVarValues1
{
	local $path = $_[0] ;
	local $bResult = 'false' ;
	local (@qryVars) = keys %qryVarValues ;

	if ($#qryVars >= 0 && $path ne '')
	{
		# Does the file exist?
		if (&CheckPathExists ($path) eq 'true')
		{
			# Wait for a shared lock
			local ($lockHandle, $lockPath, $lockMode) = &LockFile ($path, 1);

			# Open the data file for reading
			local $fileHandle = &OpenDataFileReadOnly ($path) ;

			# Read the first record (list of variable names)
			local $recData = &ReadDataFileRecord ($fileHandle) ;
			if ($recData ne '')
			{
				# Reset the number of matched records
				local $nMatchCount = 0;

				# Load the list of variable names into an array
				local (@vlst) = split (/,/, $recData) ;

				# Index the query variables
				local (%qryVarIdx) = () ;
				{
					local $qryVar ;
					foreach $qryVar (@qryVars)
					{
						for (local $iii = 0 ; $iii <= $#vlst ; $iii++)
						{
							if ($vlst[$iii] eq $qryVar)
							{
								$qryVarIdx{$qryVar} = $iii ;
								last ;
							}
						}
					}
				}

				while ($recData ne '')
				{
					# Read the next record
					$recData = &ReadDataFileRecord ($fileHandle) ;
					if ($recData ne '')
					{
						local $bMatch = 'true' ;

						# Split into an associative array of only query variable values
						local (%recQryVal) = &RecordToValuesList ($recData, \%qryVarIdx) ;

						# Compare the query values to the record's values
						local $qryVar ;
						foreach $qryVar (@qryVars)
						{
							local $qVal = $qryVarValues{$qryVar} ;
							local $rVal = $recQryVal{$qryVar} ;
							if (defined ($qryVarUTests{$qryVar}))
							{
								if (!&SafeEval ($qryVarUTests{$qryVar}))
								{
									$bMatch = 'false' ;
								}
							}
							elsif ($E_matchEmpty eq 'Yes')
							{
								if (defined ($rVal) && $rVal ne '')
								{
									if ((uc $rVal) ne (uc $qVal))
									{
										$bMatch = 'false' ;
									}
								}
							}
							elsif ((uc $rVal) ne (uc $qVal))
							{
								$bMatch = 'false' ;
							}
							last if ($bMatch eq 'false') ;
						}

						if ($bMatch eq 'true')
						{
							local (@recArray) = &RecordToValuesArray ($recData) ;
							local (%recList) = () ;

							# Increment the number of matched records counter
							$nMatchCount++ ;

							# Push variable name and value pairs into %recList
							for (local $iii = 0 ; $iii <= $#recArray ; $iii++)
							{
								$recList{$vlst[$iii]} = $recArray[$iii] ;
							}

							if ($bResult ne 'true')
							{
								%recVarValues = %recList ;
								$bResult = 'true' ;
							}

							# Continue searching for more records?
							if ($E_useMulRec eq 'Yes')
							{
								local $kkk ;
								foreach $kkk (keys %recList)
								{
									if (defined ($mulRec{$kkk}))
									{
										$mulRec{$kkk} = $mulRec{$kkk} . '|' . $recList{$kkk} ;
									}
									else
									{
										$mulRec{$kkk} = $recList{$kkk} ;
									}
								}
							}
						}
					}
					last if ($bResult eq 'true' && ($E_useMulRec ne 'Yes' || $nMatchCount >= $E_maxMulRecs)) ;
				}
			}

			# Close the data file
			close ($fileHandle) ;
			
			# Release the shared lock
			&UnlockFile ($lockHandle, $lockPath, $lockMode) ;
		}
	}
	return $bResult ;
}

# Subroutine GetRecVarValues2
#
# Searches for an existing record in the data file given the values in
# %qryVarValues. If found, stores the variable name and value pairs in
# %recVarValues. Assumes an index file is being used. If the index file
# exists, assumes it is sorted and up-to-date.

sub GetRecVarValues2
{
	my $path = $_[0] ;
	my $bResult = 'false' ;

	if ($path ne '')
	{
		# Does the data file exist?
		if (&CheckPathExists ($path) eq 'true')
		{
			# Calculate the index file path
			my $idxPath = $path . &SafeEval (&ExpandShortVarRefs ($E_indexFileExt)) ;

			# Doex the index file exist?
			if (&CheckPathExists ($idxPath) ne 'true')
			{
				local ($lockHandle, $lockPath, $lockMode) = &LockFile ($path, 2) ;	# Wait for an exclusive lock
				&WriteIndexFile ($path) ;															# Create an index file
				&UnlockFile ($lockHandle, $lockPath, $lockMode) ;							# Release the exclusive lock
			}

			# The index file should exist
			if (&CheckPathExists ($idxPath) eq 'true')
			{
				# Wait for a shared lock
				local ($lockHandle, $lockPath, $lockMode) = &LockFile ($path, 1);
				# Get array of record ids from index file
				my (@recIDs) = &GetRecIDs ($idxPath, $E_useMulRec, $E_maxMulRecs) ;
				if ($#recIDs >= 0)
				{
					# Open the data file for reading
					local $fileHandle = &OpenDataFileReadOnly ($path) ;

					# Read the first record (list of variable names)
					my $recData = &ReadDataFileRecord ($fileHandle) ;

					# Load the list of variable names into an array
					my (@vlst) = split (/,/, $recData) ;

					# Reset the number of matched records
					my $nMatchCount = 0;

					while ($recData ne '' && $#recIDs >= 0)
					{
						# Read the next record
						$recData = &ReadDataFileRecord ($fileHandle) ;
						if ($recData ne '')
						{
							my $bMatch = 'false' ;

							# Assumes the record id is in the first column
							my $nPos = index ($recData, ",") ;
							if ($nPos > 0)
							{
								# Get the record id from the first column
								my $nRecID = substr ($recData, 0, $nPos) ;
								for (my $iii = 0; $iii <= $#recIDs; $iii++)
								{
									if ($recIDs[$iii] == $nRecID)
									{
										$bMatch = 'true' ;
										splice (@recIDs, iii, 1) ;
										last ;
									}
								}
							}

							if ($bMatch eq 'true')
							{
								my (@recArray) = &RecordToValuesArray ($recData) ;
								my (%recList) = () ;

								# Increment the number of matched records counter
								$nMatchCount++ ;

								# Push variable name and value pairs into %recList
								for (my $iii = 0 ; $iii <= $#recArray ; $iii++)
								{
									$recList{$vlst[$iii]} = $recArray[$iii] ;
								}

								%recVarValues = %recList if ($nMatchCount == 1) ;
								$bResult = 'true' ;

								# Continue searching for more records?
								if ($E_useMulRec eq 'Yes')
								{
									my $kkk ;
									foreach $kkk (keys %recList)
									{
										if (defined ($mulRec{$kkk}))
										{
											$mulRec{$kkk} = $mulRec{$kkk} . '|' . $recList{$kkk} ;
										}
										else
										{
											$mulRec{$kkk} = $recList{$kkk} ;
										}
									}
								}
							}
						}
						last if ($bResult eq 'true' && ($E_useMulRec ne 'Yes' || $nMatchCount >= $E_maxMulRecs)) ;
					}
					# Close the data file
					close ($fileHandle) ;
				}

				# Release the shared lock
				&UnlockFile ($lockHandle, $lockPath, $lockMode) ;
			}
		}
	}
	return $bResult ;
}

# Subroutine GetRecIDs
#
# Searches for existing records in the index file given the values in
# %qryVarValues. If found, returns an array with the IDs of the found
# records.

sub GetRecIDs
{
	my $idxPath = $_[0] ;
	my $bUseMulRec = ($#_ >= 1 ? $_[1] : 'No') ;
	my $nMaxMulRecs = ($#_ >= 2 ? $_[2] : 1) ;
	my (@qryVarValueKeys) = keys %qryVarValues ;
	my (@qryIdxVar) = () ;									# Holds the query variable names
	my (@recIDs) = () ;										# Holds the ids of the matching records

	# Open the index file for reading
	local $idxFH = &OpenDataFileReadOnly ($idxPath) ;

	# Read the first line (version information)
	my $idxVerInfo = &ReadDataFileRecord ($idxFH) ;
	if ($idxVerInfo ne '')
	{
		my (@verInfo) = split (/,/, $idxVerInfo) ;
		if ($#verInfo >= 0)
		{
			&DieMsg ("Fatal Error", "The script cannot process your survey because it encountered unexpected version information in the index file (" . &HTMLEncodeText ($idxPath) . ".", "Please contact this site's webmaster.") if ($verInfo[0] != $kIndexFileVersion) ;

			# Calculate the size of the buffer
			my $nBufSize = $E_indexFileMinBufSize ;
			$nBufSize = int (sqrt ($verInfo[1])) if ($#verInfo > 0 && $verInfo[1] > 0) ;
			$nBufSize = $E_indexFileMinBufSize if ($nBufSize < $E_indexFileMinBufSize) ;
			$nBufSize = $E_indexFileMaxBufSize if ($nBufSize > $E_indexFileMaxBufSize) ;

			# Read the first record (list of variable names)
			my $idxRec0 = &ReadDataFileRecord ($idxFH) ;
			if ($idxRec0 ne '')
			{
				# Reset the number of matched records
				my $nMatchCount = 0;

				# Load the list of variable names into an array
				my (@vlst) = split (/,/, $idxRec0) ;

				# Initialize the %qryIdxVarPos associative array
				my (%qryIdxVarPos) = () ;
				{
					my $qryVar ;
					foreach $qryVar (@qryVarValueKeys)
					{
						for (my $iii = 0 ; $iii <= $#vlst ; $iii++)
						{
							if ($vlst[$iii] eq $qryVar)
							{
								$qryIdxVarPos{$qryVar} = $iii ;
								last ;
							}
						}
					}
				}
				# Initialize the @qryIdxVar array
				{
					my $lastVarPos = -1 ;
					foreach $qqq (keys %qryIdxVarPos)
					{
						my $nextVarPos = -1 ;
						my $qryVar ;
						foreach $qryVar (keys %qryIdxVarPos)
						{
							if (($lastVarPos < 0 || $qryIdxVarPos{$qryVar} > $lastVarPos) && ($nextVarPos < 0 || $qryIdxVarPos{$qryVar} < $nextVarPos))
							{
								$nextVarPos = $qryIdxVarPos{$qryVar} ;
								$nextQryVar = $qryVar ;
							}
						}
						push (@qryIdxVar, $nextQryVar) ;
						$lastVarPos = $nextVarPos ;
					}
				}

				for (;;)
				{
					# Read up to $nBufSize records
					my (@idxBuf) = () ;
					{
						for (my $rrr = 0; $rrr < $nBufSize; $rrr++)
						{
							my $sLine = &ReadDataFileRecord ($idxFH) ;
							last if ($sLine eq '') ;
							$idxBuf[$rrr] = $sLine ;
						}
					}
					last if ($#idxBuf < 0) ;

					my $nMatch = -1 ;
					if ($nMatchCount == 0)
					{
						# Split into an associative array of only query variable values
						my (%recQryVal) = &RecordToValuesList ($idxBuf[$#idxBuf], \%qryIdxVarPos) ;

						# Compare the query values to the record's values
						{
							my $qryVar ;
							foreach $qryVar (@qryIdxVar)
							{
								my $qVal = $qryVarValues{$qryVar} ;
								my $rVal = $recQryVal{$qryVar} ;
								$nMatch = lc ($qVal) cmp lc ($rVal) ;
								last if ($nMatch != 0) ;
							}
						}
					}
					next if ($nMatch > 0) ;

					# Look in the buffer for the matching record(s)
					{
						for (my $rrr = 0; $rrr <= $#idxBuf; $rrr++)
						{
							# Split into an associative array of only query variable values
							my (%recQryVal) = &RecordToValuesList ($idxBuf[$rrr], \%qryIdxVarPos) ;

							# Compare the query values to the record's values
							{
								my $qryVar ;
								foreach $qryVar (@qryIdxVar)
								{
									my $qVal = $qryVarValues{$qryVar} ;
									my $rVal = $recQryVal{$qryVar} ;
									$nMatch = lc ($qVal) cmp lc ($rVal) ;
									last if ($nMatch != 0) ;
								}
							}

							# Found a matching record?
							if ($nMatch == 0)
							{
								# Assumes the record id is in the first column
								my $nPos = index ($idxBuf[$rrr], ",") ;
								if ($nPos > 0)
								{
									# Get the record id from the first column
									my $nRecID = substr ($idxBuf[$rrr], 0, $nPos) ;

									# Add the record id to @recIDs
									push (@recIDs, $nRecID) ;
								}
								# Increment the number of matched records counter
								$nMatchCount++ ;
							}
							next if ($nMatch == 0 && $bUseMulRec eq 'Yes' && $nMatchCount < $nMaxMulRecs) ;
							next if ($nMatchCount == 0 && $nMatch > 0) ;
							last ;
						}
					}
					next if ($nMatch == 0 && $bUseMulRec eq 'Yes' && $nMatchCount < $nMaxMulRecs && $#idxBuf >= $nBufSize - 1) ;
					last ;
				}
			}
		}
	}
	# Close the index file
	close ($idxFH) ;

	return @recIDs ;
}

# Subroutine RecordToValuesArray
#
# Converts a record string into an array of values.

sub RecordToValuesArray
{
	local ($rec) = $_[0] ;
	local (@r2) = () ;

	$_ = $rec ;
	local ($cntQuote) = tr/"/"/ ;				# Count the number of double quotes
	if ($cntQuote > 0)
	{
		local (@r1) = split (/,/ , $rec) ;

		# Join together array entries that were separated because of the comma character but really should not be
		# because they were enclosed by double quotation marks
		{
			local ($kkk) = 0;
			for (local ($iii) = 0; $iii <= $#r1;)
			{
				$_ = $r1[$iii] ;
				local ($cntQuote) = tr/"/"/ ; # Count the number of double quotes

				if (($cntQuote % 2) != 0)		# Concatenate if the number is odd
				{
					local ($jjj) ;
					for ($jjj = $iii + 1; $jjj <= $#r1; $jjj++)
					{
						$r1[$iii] .= (',' . $r1[$jjj]) ;
						$_ = $r1[$jjj] ;
						local ($cntQuote) = tr/"/"/ ;  	# Count the number of double quotes
						last if (($cntQuote % 2) != 0);	# Break if the number is odd
					}
					$r2[$kkk++] = $r1[$iii] ;	# Assign the concatenated value to array 2
					$iii = $jjj + 1;
				}
				else
				{
					$r2[$kkk++] = $r1[$iii] ;	# Assign the value to array 2
					$iii++;
				}
			}
		}

		# Remove the beginning and ending double quotation marks and replace escaped double quotation marks with
		# non-escaped double quotation marks
		{
			for (local ($iii) = 0; $iii <= $#r2; $iii++)
			{
				$_ = $r2[$iii] ;
				local ($cntQuote) = tr/"/"/ ; # Count the number of double quotes
				if ($cntQuote > 0)
				{
					local ($value) = $r2[$iii] ;
					# Remove the beginning and ending quotation marks
					$value =~ s/^"// ;			# Remove beginning quotation mark
					$value =~ s/"$// ;			# Remove ending quotation mark
					$value =~ s/""/"/g ;			# Replace two double quotes with one

					$r2[$iii] = $value ;			# Replace value
				}
			}
		}
	}
	else
	{
		@r2 = split (/,/ , $rec) ;
	}
	return @r2 ;
}

# Subroutine RecordToValuesList
#
# Converts a record string into a new associative array of values for only
# those variables listed in the given associative array.

sub RecordToValuesList
{
	local $rec = $_[0] ;										# Get the record string
	local $hashref = $_[1] ;								# Get the list of variables
	local (%vidx) = %{$hashref} ;
	local (@vars) = keys %vidx ;
	local (%vval) = () ;
	local $cntVars = $#vars ;								# Get the variable count

   if ($cntVars >= 0)
	{
		local $idx = 0 ;
		local $pos = 0 ;
		local $pq = index ($rec, "\"", $pos) ;			# Find the first double-quotation mark

		while ($cntVars >= 0)
		{
			local $pc = index ($rec, ",", $pos) ;		# Find the next comma
			if ($pq >= 0 && $pc >= 0 && $pq < $pc)		# Does the double-quotation mark come before the comma?
			{
				while (1)
				{
					$pq = index ($rec, "\"", $pq + 1) ;					# Find the next double-quotation mark
					last if ($pq < 0) ;										# Unable to find one (this is an error condition)

					local $pq2 = index ($rec, "\"", $pq + 1) ;		# Find the next double-quotation mark
					last if ($pq2 < 0 || $pq2 > $pq + 1) ;				# Done looking for double-quotation marks if not next to each other
					$pq = $pq2 ;												# Prepare to look for the next double-quotation mark
				}
				$pc = -1 if ($pq < 0) ;										# Make the rest of the line part of the value
				$pc = index ($rec, ",", $pq + 1) if ($pq >= 0) ;	# Find the next comma
				$pq = -1 if ($pc < 0) ;
				$pq = index ($rec, "\"", $pc + 1) if ($pq >= 0 && $pc >= 0) ;	# Find the next double-quotation mark
			}

			foreach $var (keys %vidx)
			{
				if ($vidx{$var} == $idx)									# Does this position correspond to a variable we are looking for?
				{
#					$vval{$var} = "" if ($pc <= $pos) ;
					$vval{$var} = substr ($rec, $pos) if ($pc < 0) ;
					$vval{$var} = substr ($rec, $pos, $pc - $pos) if ($pc > $pos) ;

					$cntVars-- ;												# Keep track of the number of variables found
					last ;
				}
			}
			last if ($pc < 0) ;												# Stop if no more commas
			$pos = $pc + 1 ;													# Prepare for the next field
			$idx++ ;																# Increment the field index
		}

		foreach $var (keys %vidx)
		{
			$_ = $vval{$var} ;
			local $cntQuote = tr/"/"/ ;					# Count the number of double quotes
			if ($cntQuote > 0)
			{
				local $val = $vval{$var} ;
				$val =~ s/^"// ;								# Remove beginning quotation mark
				$val =~ s/"$// ;								# Remove ending quotation mark
				$val =~ s/""/"/g ;							# Replace two double quotes with one

				$vval{$var} = $val ;							# Replace value
			}
		}
	}
	return %vval ;
}

# Subroutine TrimRecVarValues
#
# Removes variables from %recVarValues that are already represented in
# %insVarValues. This is over-using %insVarValues because the intent is
# to have %insVarValues store instructions for replacing variable
# values on a form. However, it does list all of the variables that are
# on the form and the complete list is always transmitted to this
# script. The variables themselves are only transmitted when the
# respondent answers a question so %ansVarValues is not a reliable
# source for this information.

sub TrimRecVarValues
{
	# Remove variables from %recVarValues that are %insVarValues
	local ($key) ;
	foreach $key (keys %insVarValues)
	{
		if (defined ($recVarValues{$key}))
		{
			delete ($recVarValues{$key}) ;
		}
	}
	1 ; # return true
}

# Subroutine GetRules
#
# Extracts rules from %raw_data and stores them in %rules.
#
# In %rules, key stores index of rule while value stores a string which
# contains parameters used by the rule.  

sub GetRules
{
	local($name, $label, $key);
	foreach $key (keys %raw_data)
	{
		$label = substr($key,0,2) ;
		if ($label eq 'R_' && $key ne 'R_')
		{
			$name = substr($key,2) ;     # Extract rule index
			$name =~ tr/ //d ;           # $name contains index of rules.
			$rules{$name} = $raw_data{$key} ;
		}
	}
	@keys = keys %rules ;
	if ($#keys < 0)
	{
		$E_applyRule = 'No' ;
	}
	1 ; #return true
}

# Subroutine GetErrorLevel
#
# Accepts one argument: rule result triplets.
#
# Returns 'Error' if any of the results are errors.
# Otherwise, returns 'Warning' if there are any warnings.
# Otherwise returns ''.

sub GetErrorLevel
{
	local($ret) = '' ;
	local(@resLst) = @_ ;
	local($errCnt) = 0 ;
	local($wrnCnt) = 0 ;

	for (local($iii) = 0; $iii < $#resLst + 1 ; $iii += 3)
	{
		local($resTyp) = $resLst[$iii] ;
		if ($resTyp eq "Error")
		{
			$errCnt++ ;
		}
		elsif ($resTyp eq "Warning")
		{
			$wrnCnt++ ;
		}
	}

	if ($errCnt > 0)
	{
		$ret = 'Error' ;
	}
	elsif ($wrnCnt > 0)
	{
		$ret = 'Warning' ;
	}
	return $ret ;
}

# Subroutine RunNumberRule
#
# Returns '' if the value of the variable is a number.
# Otherwise, returns an error, msg1, msg2 triplet.
#
# Expects 2 arguments: operation and variable name.

sub RunNumberRule
{
	local (@para) = @_ ;
	push (@para, $E_msgRuleNotNum) ;
	return &RunNumberRule2 (@para) ;
}

# Subroutine RunRangeRule
#
# Returns '' when the value of the variable is within the range given
# by minimum and maximum. Otherwise, returns warning, msg1, msg2 triplet.
#
# Expects 4 arguments: operation, variable name, minimum and maximum.

sub RunRangeRule
{
	local (@para) = @_ ;
	push (@para, $E_msgRuleNotNum) ;
	push (@para, $E_msgRuleMinNum) ;
	push (@para, $E_msgRuleMaxNum) ;
	return &RunRangeRule2 (@para) ;
}

# Subroutine RunRankRule
#
# Returns ''  when for the ranked rankees:
#		no two rankees have the same rank
#		the lowest rank is 1
#		the highest rank is the total number of ranked rankees.
#
# Otherwise, returns error/warning, msg1, msg2 triplets.
#
# Expects 2+N arguments: operation, N and N variable names.

sub RunRankRule
{
	local (@para) = @_ ;
	local $op = shift @para ;
	unshift (@para, $E_msgRuleRnkGap) ;
	unshift (@para, $E_msgRuleRnkOne) ;
	unshift (@para, $E_msgRulePosNum) ;
	unshift (@para, $E_msgRuleMaxNum) ;
	unshift (@para, $E_msgRuleMinNum) ;
	unshift (@para, $E_msgRuleNotNum) ;
	unshift (@para, $op) ;
	return &RunRankRule2 (@para) ;
}

# Subroutine RunCSumRule
#
# Returns '' when the sum of the variables is equal to sumOfAll.
# Otherwise, returns error/warning, msg1, msg2 triplets.
#
# Expects 2+N+1 arguments: operation, N, N variable names and sumOfAll.

sub RunCSumRule
{
	local (@para) = @_ ;
	local ($op) = shift @para ;
	local ($sumOfAll) = pop @para ;
	unshift (@para, $sumOfAll) ;
	unshift (@para, $E_msgRuleCsmSum) ;
	unshift (@para, $E_msgRulePosNum) ;
	unshift (@para, $E_msgRuleMaxNum) ;
	unshift (@para, $E_msgRuleMinNum) ;
	unshift (@para, $E_msgRuleNotNum) ;
	unshift (@para, $op) ;
	return &RunCSumRule2 (@para) ;
}

# Subroutine RunRequiredRule
#
# Returns '' when at least one variable has a response.
# Otherwise, returns error, msg1, msg2 triplets.
#
# Expects 2+N arguments: operation, N and N variable names.

sub RunRequiredRule
{
	local (@para) = @_ ;
	local ($op) = shift @para ;
	unshift (@para, $E_msgRuleReqRsp) ;
	unshift (@para, $op) ;
	return &RunRequiredRule2 (@para) ;
}

# Subroutine RunMissingRule
#
# Returns '' when at least one variable has a response.
# Otherwise, returns warning, msg1, msg2 triplets.
#
# Expects 2+N arguments: operation, N and N variable names.

sub RunMissingRule
{
	local (@para) = @_ ;
	local ($op) = shift @para ;
	unshift (@para, $E_msgRuleMisRsp) ;
	unshift (@para, $op) ;
	return &RunMissingRule2 (@para) ;
}

# Subroutine RunLimitSubmitsRule
#
# returns error, msg1, msg2 triplets.

sub RunLimitSubmitsRule
{
	local ($ret) = '' ;
	local (@msg) = @_ ;
	local ($op) = shift @msg ;
	local ($max) = shift @msg ;

	if ($op eq $kSaving)
	{
		if ($E_recCntVar ne '')
		{
			local $recCnt = 0 ;
			if ($fwdVarValues{$E_recCntVar} =~ m/^\d+$E_decimalPoint\d+$/)
			{
				($recCnt) = ($fwdVarValues{$E_recCntVar} =~ m/^(\d+)$E_decimalPoint\d+$/) ;
			}
			else
			{
				$recCnt = $fwdVarValues{$E_recCntVar} ;
			}
			if ($recCnt > $max)
			{
				local ($m) = $msg[0];
				if ($max != 1)
				{
					$m = sprintf ($msg[1], $recCnt - 1, $max) ;
				}
				$ret = "Error" .
						 $kErrMsgDelimiter .
						 &HTMLEncodeText ($m) .
						 $kErrMsgDelimiter .
						 &HTMLEncodeText ($m) ;
			}
		}
	}
	return $ret ;
}

# Subroutine RunLimitRespondentsRule
#
# returns error, msg1, msg2 triplets.

sub RunLimitRespondentsRule
{
	local ($ret) = '' ;
	local (@msg) = @_ ;
	local ($op) = shift @msg ;

	if ($op eq $kSaving)
	{
		if ((%qryVarValues && (!defined ($qryVarValues{$E_recIDVar}))) && ($globalFields{$kg_GetRecVarValues} ne 'true'))
		{
			$ret = "Error" .
					 $kErrMsgDelimiter .
					 &HTMLEncodeText ($msg[0]) .
					 $kErrMsgDelimiter .
					 &HTMLEncodeText ($msg[0]) ;
		}
	}
	return $ret ;
}

# Subroutine RunEnterKeyDoesNotSubmitRule
#
# returns error, msg1, msg2 triplets.

sub RunEnterKeyDoesNotSubmitRule
{
	local ($ret) = '' ;
	local (@msg) = @_ ;
	local ($op) = shift @msg ;

	if ($op eq $kSaving)
	{
		if ((!defined ($raw_data{'E_nextButton'})) &&
			 (!defined ($raw_data{'E_backButton'})) &&
			 (!defined ($raw_data{'E_nextIgnoreWarnings'})) &&
			 (!defined ($raw_data{'E_bookmarkButton'})) &&
			 (!defined ($raw_data{'E_calcButton'})))
		{
			$ret = "Error" .
					 $kErrMsgDelimiter .
					 &HTMLEncodeText ($msg[0]) .
					 $kErrMsgDelimiter .
					 &HTMLEncodeText ($msg[0]) ;
		}
	}
	return $ret ;
}

# Subroutine RunAuthorizationRule
#
# Accepts four arguments: operation, variable name, value and message.
#
# Returns '' when the value of the variable is equal to the expected
# value. Otherwise, returns error, msg1, msg2 triplet.

sub RunAuthorizationRule
{
	local($ret) = '' ;
	local(@para) = @_ ;
	local($op, $varName, $eValue, $msg) = ($para[0], $para[1], $para[2], $para[3]) ;

	if (defined $ansVarValues{$varName})
	{
		local ($value) = $ansVarValues{$varName} ;
		if ((uc $value) ne (uc $eValue))
		{
			$ret = "Error" .
					 $kErrMsgDelimiter .
					 &HTMLEncodeText ($msg) .
					 $kErrMsgDelimiter .
					 &HTMLEncodeText ($msg) ;
		}
	}
	else
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 &HTMLEncodeText ($msg) .
				 $kErrMsgDelimiter .
				 &HTMLEncodeText ($msg) ;
	}
	return $ret ;
}

# Subroutine RunExprRule
#
# Accepts three arguments: operation, expression and message.
#
# Returns '' when the value of the expression is true.
# Otherwise, returns error/warning, msg1, msg2 triplet.

sub RunExprRule
{
	local $ret = '' ;
	local (@para) = @_ ;
	local ($op, $expr, $msg) = ($para[0], $para[1], $para[2]) ;
	local $result = &SafeEval (&ExpandShortVarRefs (&TagDecodeText ($expr))) ;
	if ($@)
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" ;
	}
	elsif ($result == 2)
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 &HTMLEncodeText (&TagDecodeText ($msg)) .
				 $kErrMsgDelimiter .
				 &HTMLEncodeText (&TagDecodeText ($msg)) ;
	}
	elsif ($result == 1)
	{
		$ret = "Warning" .
				 $kErrMsgDelimiter .
				 &HTMLEncodeText (&TagDecodeText ($msg)) .
				 $kErrMsgDelimiter .
				 &HTMLEncodeText (&TagDecodeText ($msg)) ;
	}
	return $ret ;
}

# Subroutine RunExpr2Rule
#
# Accepts three arguments: operation, expression and message.
#
# Returns '' when the value of the expression is true.
# Otherwise, returns error/warning, msg1, msg2 triplet.

sub RunExpr2Rule
{
	local $ret = '' ;
	local (@para) = @_ ;
	local ($op, $expr, $msg) = ($para[0], $para[1], $para[2]) ;
	local $result = &SafeEval (&ExpandShortVarRefs (&SafeEval (&ExpandShortVarRefs (&TagDecodeText ($expr))))) ;
	if ($@)
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" ;
	}
	elsif ($result == 2)
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 &HTMLEncodeText (&TagDecodeText ($msg)) .
				 $kErrMsgDelimiter .
				 &HTMLEncodeText (&TagDecodeText ($msg)) ;
	}
	elsif ($result == 1)
	{
		$ret = "Warning" .
				 $kErrMsgDelimiter .
				 &HTMLEncodeText (&TagDecodeText ($msg)) .
				 $kErrMsgDelimiter .
				 &HTMLEncodeText (&TagDecodeText ($msg)) ;
	}
	return $ret ;
}

# Subroutine RunNumberRule2
#
# Returns '' if the value of the variable is a number.
# Otherwise, returns an error, msg1, msg2 triplet.
#
# Expects 3 arguments: operation, variable name and invalid number
# message.

sub RunNumberRule2
{
	local $ret = '' ;
	local (@para) = @_ ;
	local ($op, $varName, $numExpr) = ($para[0], $para[1], $para[2]) ;

	if (defined $ansVarValues{$varName})
	{
		# Construct a regular expression to determine if number
		local $dp = quotemeta ($E_decimalPoint);
		local $pat = '^(\s*\-?\d+' . $dp . '?\d*|\-?' . $dp . '\d+\s*)$' ;

		local $value = $ansVarValues{$varName} ;
		# Does the value match a valid number?
		$_ = $value ;
		if (! /$pat/)
		{
			local $errMsg = &SafeEval (qq/"$numExpr"/) ;
			if ($@)
			{
				$ret = "Error" .
						 $kErrMsgDelimiter .
						 "Syntax error in rule message \"".&HTMLEncodeText ($numExpr)."\": $@" .
						 $kErrMsgDelimiter .
						 "Syntax error in rule message \"".&HTMLEncodeText ($numExpr)."\": $@" ;
			}
			else
			{
				$ret = "Error" .
						 $kErrMsgDelimiter .
						 &HTMLEncodeText ($errMsg) .
						 $kErrMsgDelimiter .
						 &HTMLEncodeText ($errMsg) ;
			}
		}
	}
	return $ret ;
}

# Subroutine RunRangeRule2
#
# Returns '' when the value of the variable is within the range given
# by minimum and maximum. Otherwise, returns a warning, msg1, msg2 triplet.
#
# Expects 7 arguments:
#
#		operation
#		variable name
#		minimum
#		maximum
#		invalid number message
#		less than minimum message
#		greater than maximum message

sub RunRangeRule2
{
	local $ret = '' ;
	local (@para) = @_ ;
	local ($op, $varName, $min, $max, $numExpr, $minExpr, $maxExpr) = ($para[0], $para[1], $para[2], $para[3], $para[4], $para[5], $para[6]) ;

	$min =~ s/\s+//g ;		# Remove all white space
	$max =~ s/\s+//g ;		# Remove all white space

	if (defined $ansVarValues{$varName})
	{
		local $numberRuleSpec = "$op,$varName,$numExpr" ;
		local (@numberRuleData) = split (/,/, $numberRuleSpec) ;
		$ret = &RunNumberRule2 (@numberRuleData) ;

		if ($ret eq '')
		{
			local $value = $ansVarValues{$varName} ;
			if ($value < $min)
			{
				local $errMsg = &SafeEval (qq/"$minExpr"/) ;
				if ($@)
				{
					$ret = "Error" .
							 $kErrMsgDelimiter .
							 "Syntax error in rule message \"".&HTMLEncodeText ($minExpr)."\": $@" .
							 $kErrMsgDelimiter .
							 "Syntax error in rule message \"".&HTMLEncodeText ($minExpr)."\": $@" ;
				}
				else
				{
					$ret = "Warning" .
							 $kErrMsgDelimiter .
							 &HTMLEncodeText ($errMsg) .
							 $kErrMsgDelimiter .
							 &HTMLEncodeText ($errMsg) ;
				}
			}
			elsif ($value > $max)
			{
				local $errMsg = &SafeEval (qq/"$maxExpr"/) ;
				if ($@)
				{
					$ret = "Error" .
							 $kErrMsgDelimiter .
							 "Syntax error in rule message \"".&HTMLEncodeText ($maxExpr)."\": $@" .
							 $kErrMsgDelimiter .
							 "Syntax error in rule message \"".&HTMLEncodeText ($maxExpr)."\": $@" ;
				}
				else
				{
					$ret = "Warning" .
							 $kErrMsgDelimiter .
							 &HTMLEncodeText ($errMsg) .
							 $kErrMsgDelimiter .
							 &HTMLEncodeText ($errMsg) ;
				}
			}
		}
	}
	return $ret ;
}

# Subroutine RunRankRule2
#
# Returns ''  when for the ranked rankees:
#		no two rankees have the same rank
#		the lowest rank is 1
#		the highest rank is the total number of ranked rankees.
#
# Otherwise, returns error/warning, msg1, msg2 triplets.
#
# Expects 8+N arguments:
#
#		operation
#		invalid number message
#		less than minimum message
#		greater than maximum message
#		not positive number message
#		doesn't start at 1 message
#		not consecutive message
#		N
#		list of N variable names

sub RunRankRule2
{
	local $ret = '' ;
	local (@vars) = @_ ;
	local $op = shift @vars ;
	local $numExpr = shift @vars ;
	local $minExpr = shift @vars ;
	local $maxExpr = shift @vars ;
	local $posExpr = shift @vars ;
	local $oneExpr = shift @vars ;
	local $conExpr = shift @vars ;
	local $numOfVars = shift @vars ;
	local $gotVars = $#vars + 1 ;

	# Check whether the number of variables in @vars is equal to $numOfVars.
	if ($numOfVars != $gotVars)
	{
		&DieMsg ("Fatal Error", "Subroutine RunRankRule2 expected " . &HTMLEncodeText ($numOfVars) . " variable(s) but got " . &HTMLEncodeText ($gotVars) . ".", "Please contact this site's webmaster.") ;
	}

	local (@rankedRankees) = ();
	local ($iii, $numOfRankees) = (0, 0);

	for ($iii = 0; $iii < $numOfVars ; $iii++)
	{
		if (defined $ansVarValues{$vars[$iii]} )
		{
			local $rangeRuleSpec = "$op,$vars[$iii],1,$numOfVars,$numExpr,$minExpr,$maxExpr" ;
			local (@rangeRuleData) = split (/,/, $rangeRuleSpec) ;
			local $res = &RunRangeRule2 (@rangeRuleData) ;

			if ($res ne '')
			{
				$ret .= $kErrMsgDelimiter if ($ret ne '') ;
				$ret .= $res ;
			}
			else
			{
				local $value = $ansVarValues{$vars[$iii]} ;

				$value =~ s/^\s+//;	# Remove beginning white space
				$value =~ s/\s+$//;	# Remove ending white space
				$_ = $value ;
				if (/\D/)
				{
					local $errMsg = &SafeEval (qq/"$posExpr"/) ;
					if ($@)
					{
						$ret .= $kErrMsgDelimiter if ($ret ne '') ;
						$ret .= "Error" .
								  $kErrMsgDelimiter .
								  "Syntax error in rule message \"".&HTMLEncodeText ($posExpr)."\": $@" .
								  $kErrMsgDelimiter .
								  "Syntax error in rule message \"".&HTMLEncodeText ($posExpr)."\": $@" ;
					}
					else
					{
						$ret .= $kErrMsgDelimiter if ($ret ne '') ;
						$ret .= "Warning" .
								  $kErrMsgDelimiter .
								  &HTMLEncodeText ($errMsg) .
								  $kErrMsgDelimiter .
								  &HTMLEncodeText ($errMsg) ;
					}
				}
				else
				{
					$rankedRankees[$numOfRankees] = $value ;
					$numOfRankees++ ;
				}
			}
		}
	}

	if ($numOfRankees > 0)
	{
		local (@sortedRankees) = sort { $a <=> $b } @rankedRankees ;

		for ($iii = 0 ; $iii < $numOfRankees ; $iii++)
		{
			if ($sortedRankees[$iii] != $iii + 1)
			{
				if ($iii == 0)
				{
					local $errMsg = &SafeEval (qq/"$oneExpr"/) ;
					if ($@)
					{
						$ret .= $kErrMsgDelimiter if ($ret ne '') ;
						$ret .= "Error" .
								  $kErrMsgDelimiter .
								  "Syntax error in rule message \"".&HTMLEncodeText ($oneExpr)."\": $@" .
								  $kErrMsgDelimiter .
								  "Syntax error in rule message \"".&HTMLEncodeText ($oneExpr)."\": $@" ;
					}
					else
					{
						$ret .= $kErrMsgDelimiter if ($ret ne '') ;
						$ret .= "Warning" .
								  $kErrMsgDelimiter .
								  &HTMLEncodeText ($errMsg) .
								  $kErrMsgDelimiter .
								  &HTMLEncodeText ($errMsg) ;
					}
				}
				else
				{
					local $errMsg = &SafeEval (qq/"$conExpr"/) ;
					if ($@)
					{
						$ret .= $kErrMsgDelimiter if ($ret ne '') ;
						$ret .= "Error" .
								  $kErrMsgDelimiter .
								  "Syntax error in rule message \"".&HTMLEncodeText ($conExpr)."\": $@" .
								  $kErrMsgDelimiter .
								  "Syntax error in rule message \"".&HTMLEncodeText ($conExpr)."\": $@" ;
					}
					else
					{
						$ret .= $kErrMsgDelimiter if ($ret ne '') ;
						$ret .= "Warning" .
								  $kErrMsgDelimiter .
								  &HTMLEncodeText ($errMsg) .
								  $kErrMsgDelimiter .
								  &HTMLEncodeText ($errMsg) ;
					}
				}
				last ;
			}
		}
	}
	return $ret ;
}

# Subroutine RunCSumRule2
#
# Returns '' when the sum of the variables is equal to sumOfAll.
# Otherwise, returns error/warning, msg1, msg2 triplets.
#
# Expects 8+N arguments:
#
#		operation
#		invalid number message
#		less than minimum message
#		greater than maximum message
#		not positive number message
#		does not sum to sumOfAll message
#		sumOfAll
#		N
#		list of N variable names

sub RunCSumRule2
{
   local $ret = '' ;
	local (@vars) = @_ ;
	local $op = shift @vars ;
	local $numExpr = shift @vars ;
	local $minExpr = shift @vars ;
	local $maxExpr = shift @vars ;
	local $posExpr = shift @vars ;
	local $sumExpr = shift @vars ;
	local $sumOfAll = shift @vars ;
	local $numOfVars = shift @vars ;
	local $cnt = 0 ;
	local $sum = 0 ;
	local $gotVars = $#vars + 1 ;

   # Check whether the number of variables in @vars is equal to $numOfVars.
	if ($numOfVars != $gotVars)
	{
		&DieMsg ("Fatal Error", "Subroutine RunCSumRule2 expected " . &HTMLEncodeText ($numOfVars) . " variable(s) but got " . &HTMLEncodeText ($gotVars) . ".", "Please contact this site's webmaster.") ;
	}

	for (local $iii = 0; $iii < $numOfVars ; $iii++)
	{
		local $name = $vars[$iii] ;
		if (defined ($ansVarValues{$name}))
		{
			local $rangeRuleSpec = "$op,$name,0,$sumOfAll,$numExpr,$minExpr,$maxExpr" ;
			local (@rangeRuleData) = split (/,/, $rangeRuleSpec) ;
			local $res = &RunRangeRule2 (@rangeRuleData) ;
			local $errLev = '' ;

			if ($res ne '')
			{
				local (@resLst) = split (/$kErrMsgDelimiter/, $res) ;
				$errLev = &GetErrorLevel (@resLst) ;
			}

			if ($errLev ne 'Error')
			{
				local $value = $ansVarValues{$name} ;

				$value =~ s/^\s+//;	# Remove beginning white space
				$value =~ s/\s+$//;	# Remove ending white space
				$_ = $value ;
				if (/\D/)
				{
					local $errMsg = &SafeEval (qq/"$posExpr"/) ;
					if ($@)
					{
						$ret .= $kErrMsgDelimiter if ($ret ne '') ;
						$ret .= "Error" .
								  $kErrMsgDelimiter .
								  "Syntax error in rule message \"".&HTMLEncodeText ($posExpr)."\": $@" .
								  $kErrMsgDelimiter .
								  "Syntax error in rule message \"".&HTMLEncodeText ($posExpr)."\": $@" ;
						$errLev = 'Error' ;		# Assign an error level
					}
					else
					{
						$res .= $kErrMsgDelimiter if ($res ne '') ;
						$res .= "Warning" .
								  $kErrMsgDelimiter .
								  &HTMLEncodeText ($errMsg) .
								  $kErrMsgDelimiter .
								  &HTMLEncodeText ($errMsg) ;
						$errLev = 'Warning' ;	# Assign a warning level
					}
				}

				$cnt++ ;
				$sum += $value ;	# Include number in sum if it does not cause an error
			}

			if ($res ne '')
			{
				$ret .= $kErrMsgDelimiter if ($ret ne '') ;
				$ret .= $res ;
			}
		}
	}
	if ($cnt > 0 && $sum != $sumOfAll)
	{
		local $errMsg = &SafeEval (qq/"$sumExpr"/) ;
		if ($@)
		{
			$ret .= $kErrMsgDelimiter if ($ret ne '') ;
			$ret .= "Error" .
					  $kErrMsgDelimiter .
					  "Syntax error in rule message \"".&HTMLEncodeText ($sumExpr)."\": $@" .
					  $kErrMsgDelimiter .
					  "Syntax error in rule message \"".&HTMLEncodeText ($sumExpr)."\": $@" ;
		}
		else
		{
			$ret .= $kErrMsgDelimiter if ($ret ne '') ;
			$ret .= "Warning" .
					  $kErrMsgDelimiter .
					  &HTMLEncodeText ($errMsg) .
					  $kErrMsgDelimiter .
					  &HTMLEncodeText ($errMsg) ;
		}
	}
	return $ret ;
}

# Subroutine RunRequiredRule2
#
# Returns '' when at least one variable has a response.
# Otherwise, returns error, msg1, msg2 triplet.
#
# Expects 3+N arguments:
#
#		operation
#		required message
#		N
#		list of N variable names.

sub RunRequiredRule2
{
	local $ret = '' ;
	local (@vars) = @_ ;
	local $op = shift @vars ;

	if ($op eq $kSaving)
	{
		local $reqExpr = shift @vars ;
		local $numOfVars = shift @vars ;
		local $gotVars = $#vars + 1 ;

		# Check whether the number of variables in @vars is equal to $numOfVars.
		if ($numOfVars != $gotVars)
		{
			&DieMsg ("Fatal Error", "Subroutine RunRequiredRule2 expected " . &HTMLEncodeText ($numOfVars) . " variables but got " . &HTMLEncodeText ($gotVars) . ".", "Please contact this site's webmaster.") ;
		}

		local $defd = 'no' ;
		for (local $iii = 0; $iii < $numOfVars ; $iii++)
		{
			if (!defined ($insVarValues{$vars[$iii]}) || defined ($ansVarValues{$vars[$iii]}))
			{
				$defd = 'yes' ;
				last ;
			}
		}

		if ($defd eq 'no')
		{
			local $errMsg = &SafeEval (qq/"$reqExpr"/) ;
			if ($@)
			{
				$ret .= $kErrMsgDelimiter if ($ret ne '') ;
				$ret .= "Error" .
						  $kErrMsgDelimiter .
						  "Syntax error in rule message \"".&HTMLEncodeText ($reqExpr)."\": $@" .
						  $kErrMsgDelimiter .
						  "Syntax error in rule message \"".&HTMLEncodeText ($reqExpr)."\": $@" ;
			}
			else
			{
				$ret .= $kErrMsgDelimiter if ($ret ne '') ;
				$ret .= "Error" .
						  $kErrMsgDelimiter .
						  &HTMLEncodeText ($errMsg) .
						  $kErrMsgDelimiter .
						  &HTMLEncodeText ($errMsg) ;
			}
		}
	}
	return $ret ;
}

# Subroutine RunMissingRule2
#
# Returns '' when at least one variable has a response.
# Otherwise, returns warning, msg1, msg2 triplet.
#
# Expects 3+N arguments:
#
#		operation
#		missing message
#		N
#		list of N variable names

sub RunMissingRule2
{
	local $ret = '' ;
	local (@vars) = @_ ;
	local $op = shift @vars ;

	if ($op eq $kSaving)
	{
		local $misExpr = shift @vars ;
		local $numOfVars = shift @vars ;
		local $gotVars = $#vars + 1 ;

		# Check whether the number of variables in @vars is equal to $numOfVars.
		if ($numOfVars != $gotVars)
		{
			&DieMsg ("Fatal Error", "Subroutine RunMissingRule2 expected " . &HTMLEncodeText ($numOfVars) . " variables but got " . &HTMLEncodeText ($gotVars) . ".", "Please contact this site's webmaster.") ;
		}

		local $defd = 'no' ;
		for (local $iii = 0; $iii < $numOfVars ; $iii++)
		{
			if (!defined ($insVarValues{$vars[$iii]}) || defined ($ansVarValues{$vars[$iii]}))
			{
				$defd = 'yes' ;
				last ;
			}
		}

		if ($defd eq 'no')
		{
			local $errMsg = &SafeEval (qq/"$misExpr"/) ;
			if ($@)
			{
				$ret .= $kErrMsgDelimiter if ($ret ne '') ;
				$ret .= "Error" .
						  $kErrMsgDelimiter .
						  "Syntax error in rule message \"".&HTMLEncodeText ($misExpr)."\": $@" .
						  $kErrMsgDelimiter .
						  "Syntax error in rule message \"".&HTMLEncodeText ($misExpr)."\": $@" ;
			}
			else
			{
				$ret .= $kErrMsgDelimiter if ($ret ne '') ;
				$ret .= "Warning" .
						  $kErrMsgDelimiter .
						  &HTMLEncodeText ($errMsg) .
						  $kErrMsgDelimiter .
						  &HTMLEncodeText ($errMsg) ;
			}
		}
	}
	return $ret ;
}

# Subroutine RunRequiredRule3
#
# Returns '' when at least M or at most P variables have a response.
# Otherwise, returns error, msg1, msg2 triplets.
#
# Expects 7+N arguments: operation, N,M,P and N variable names.

sub RunRequiredRule3
{
	local (@para) = @_ ;
	local ($op) = shift @para ;
	unshift (@para, $E_msgRuleAllReq) ;
	unshift (@para, $E_msgRuleExaReq) ;
	unshift (@para, $E_msgRuleMaxReq) ;
	unshift (@para, $E_msgRuleMinMaxReq) ;
	unshift (@para, $E_msgRuleMinReq) ;
	unshift (@para, $op) ;
	return &RunRequiredRule4 (@para) ;
}

# Subroutine RunRequiredRule4
#
# Returns '' when at least M or at most P variables have a response.
# Otherwise, returns error, msg1, msg2 triplet.
#
# Expects 9+N arguments:
#
#		operation
#		minimum required message
#		minimum and maximum required message
#		maximum required message
#		exact required message
#		all required message
#		N (total number of variables)
#		M (minimum number of variables with answers)
#		P (maximum number of variables with answers)
#		list of N variable names.

sub RunRequiredRule4
{
	local $ret = '' ;
	local (@vars) = @_ ;
	local $op = shift @vars ;

	if ($op eq $kSaving)
	{
		local $minReqExpr = shift @vars ;
		local $minMaxReqExpr = shift @vars ;
		local $maxReqExpr = shift @vars ;
		local $exaReqExpr = shift @vars ;
		local $allReqExpr = shift @vars ;
		local $numOfVars = shift @vars ;
		local $minDefVars = shift @vars ;
		local $maxDefVars = shift @vars ;
		local $gotVars = $#vars + 1 ;
		local $defVars = 0;
		local $hidVars = 0;

		# Check whether the number of variables in @vars is equal to $numOfVars.
		if ($numOfVars != $gotVars)
		{
			&DieMsg ("Fatal Error", "Subroutine RunRequiredRule4 expected " . &HTMLEncodeText ($numOfVars) . " variables but got " . &HTMLEncodeText ($gotVars) . ".", "Please contact this site's webmaster.") ;
		}

		for (local $iii = 0; $iii < $numOfVars ; $iii++)
		{
			if (!defined ($insVarValues{$vars[$iii]}))
			{
				$hidVars++ ;
			}
			elsif (defined ($ansVarValues{$vars[$iii]}))
			{
				$defVars++ ;
			}
		}

		$numOfVars -= $hidVars if ($hidVars > 0) ;
		$minDefVars = $numOfVars if ($hidVars > 0 && $minDefVars > $numOfVars) ;
		$maxDefVars = $numOfVars if ($hidVars > 0 && $maxDefVars > $numOfVars) ;

		if ($defVars < $minDefVars || $defVars > $maxDefVars)
		{
			local $errExpr ;

			$errExpr = $minMaxReqExpr	if (($minDefVars > 0 && ($minDefVars < $numOfVars && $minDefVars != $maxDefVars)) && ($maxDefVars < $numOfVars)) ;
			$errExpr = $minReqExpr		if (($minDefVars > 0 && ($minDefVars < $numOfVars && $minDefVars != $maxDefVars)) && ($maxDefVars >= $numOfVars)) ;
			$errExpr = $maxReqExpr		if ($minDefVars <= 0) ;
			$errExpr = $exaReqExpr		if (($minDefVars > 0 && ($minDefVars < $numOfVars && $minDefVars == $maxDefVars))) ;
			$errExpr = $allReqExpr		if (($minDefVars > 0 && ($minDefVars >= $numOfVars)));
			local $errMsg = &SafeEval (qq/"$errExpr"/) ;
			if ($@)
			{
				$ret .= $kErrMsgDelimiter if ($ret ne '') ;
				$ret .= "Error" .
						  $kErrMsgDelimiter .
						  "Syntax error in rule message \"".&HTMLEncodeText ($errExpr)."\": $@" .
						  $kErrMsgDelimiter .
						  "Syntax error in rule message \"".&HTMLEncodeText ($errExpr)."\": $@" ;
			}
			else
			{
				$ret .= $kErrMsgDelimiter if ($ret ne '') ;
				$ret .= "Error" .
						  $kErrMsgDelimiter .
						  &HTMLEncodeText ($errMsg) .
						  $kErrMsgDelimiter .
						  &HTMLEncodeText ($errMsg) ;
			}
		}
	}
	return $ret ;
}

# Subroutine RunMissingRule3
#
# Returns '' when at least M or at most P variables have a response.
# Otherwise, returns warning, msg1, msg2 triplets.
#
# Expects 7+N arguments: operation, N,M,P and N variable names.

sub RunMissingRule3
{
	local (@para) = @_ ;
	local ($op) = shift @para ;
	unshift (@para, $E_msgRuleAllMis) ;
	unshift (@para, $E_msgRuleExaMis) ;
	unshift (@para, $E_msgRuleMaxMis) ;
	unshift (@para, $E_msgRuleMinMaxMis) ;
	unshift (@para, $E_msgRuleMinMis) ;
	unshift (@para, $op) ;
	return &RunMissingRule4 (@para) ;
}

# Subroutine RunMissingRule4
#
# Returns '' when at least M or at most P variables have a response.
# Otherwise, returns warning, msg1, msg2 triplet.
#
# Expects 9+N arguments:
#
#		operation
#		minimum missing message
#		minimum and maximum missing message
#		maximum missing message
#		exact missing message
#		all missing message
#		N (total number of variables)
#		M (minimum number of variables with answers)
#		P (maximum number of variables with answers)
#		list of N variable names.

sub RunMissingRule4
{
	local $ret = '' ;
	local (@vars) = @_ ;
	local $op = shift @vars ;

	if ($op eq $kSaving)
	{
		local $minMisExpr = shift @vars ;
		local $minMaxMisExpr = shift @vars ;
		local $maxMisExpr = shift @vars ;
		local $exaMisExpr = shift @vars ;
		local $allMisExpr = shift @vars ;
		local $numOfVars = shift @vars ;
		local $minDefVars = shift @vars ;
		local $maxDefVars = shift @vars ;
		local $gotVars = $#vars + 1 ;
		local $defVars = 0;
		local $hidVars = 0;

		# Check whether the number of variables in @vars is equal to $numOfVars.
		if ($numOfVars != $gotVars)
		{
			&DieMsg ("Fatal Error", "Subroutine RunMissingRule4 expected " . &HTMLEncodeText ($numOfVars) . " variables but got " . &HTMLEncodeText ($gotVars) . ".", "Please contact this site's webmaster.") ;
		}

		for (local $iii = 0; $iii < $numOfVars ; $iii++)
		{
			if (!defined ($insVarValues{$vars[$iii]}))
			{
				$hidVars++ ;
			}
			elsif (defined ($ansVarValues{$vars[$iii]}))
			{
				$defVars++ ;
			}
		}

		$numOfVars -= $hidVars if ($hidVars > 0) ;
		$minDefVars = $numOfVars if ($hidVars > 0 && $minDefVars > $numOfVars) ;
		$maxDefVars = $numOfVars if ($hidVars > 0 && $maxDefVars > $numOfVars) ;

		if ($defVars < $minDefVars || $defVars > $maxDefVars)
		{
			local $errExpr ;

			$errExpr = $minMaxMisExpr	if (($minDefVars > 0 && ($minDefVars < $numOfVars && $minDefVars != $maxDefVars)) && ($maxDefVars < $numOfVars)) ;
			$errExpr = $minMisExpr		if (($minDefVars > 0 && ($minDefVars < $numOfVars && $minDefVars != $maxDefVars)) && ($maxDefVars >= $numOfVars)) ;
			$errExpr = $maxMisExpr		if ($minDefVars <= 0) ;
			$errExpr = $exaMisExpr		if (($minDefVars > 0 && ($minDefVars < $numOfVars && $minDefVars == $maxDefVars))) ;
			$errExpr = $allMisExpr		if (($minDefVars > 0 && ($minDefVars >= $numOfVars)));
			local $errMsg = &SafeEval (qq/"$errExpr"/) ;
			if ($@)
			{
				$ret .= $kErrMsgDelimiter if ($ret ne '') ;
				$ret .= "Error" .
						  $kErrMsgDelimiter .
						  "Syntax error in rule message \"".&HTMLEncodeText ($errExpr)."\": $@" .
						  $kErrMsgDelimiter .
						  "Syntax error in rule message \"".&HTMLEncodeText ($errExpr)."\": $@" ;
			}
			else
			{
				$ret .= $kErrMsgDelimiter if ($ret ne '') ;
				$ret .= "Warning" .
						  $kErrMsgDelimiter .
						  &HTMLEncodeText ($errMsg) .
						  $kErrMsgDelimiter .
						  &HTMLEncodeText ($errMsg) ;
			}
		}
	}
	return $ret ;
}

# Subroutine RunYesReqRule1
#
# Returns '' when at least M or at most P variables have a yes response.
# Otherwise, returns error, msg1, msg2 triplets.
#
# Expects 6+N arguments:
#
#     operation
#		G (total number of groups)
#		V (number of variables in each group)
#		N (total number of variables)
#		M (minimum number of variables with answers)
#		P (maximum number of variables with answers)
#     list of N variable names.

sub RunYesReqRule1
{
	local (@para) = @_ ;
	local ($op) = shift @para ;
	unshift (@para, $E_msgRuleExaYesReq) ;
	unshift (@para, $E_msgRuleMaxYesReq) ;
	unshift (@para, $E_msgRuleMinMaxYesReq) ;
	unshift (@para, $E_msgRuleMinYesReq) ;
	unshift (@para, $op) ;
	return &RunYesReqRule2 (@para) ;
}

# Subroutine RunYesReqRule2
#
# Returns '' when at least M or at most P variables have a yes response.
# Otherwise, returns error, msg1, msg2 triplet.
#
# Expects 10+N arguments:
#
#		operation
#		minimum required message
#		minimum and maximum required message
#		maximum required message
#		exact required message
#		G (total number of groups)
#		V (number of variables in each group)
#		N (total number of variables)
#		M (minimum number of variables with answers)
#		P (maximum number of variables with answers)
#		list of N variable names.

sub RunYesReqRule2
{
	local $ret = '' ;
	local (@vars) = @_ ;
	local $op = shift @vars ;

	if ($op eq $kSaving)
	{
		local $minReqExpr = shift @vars ;
		local $minMaxReqExpr = shift @vars ;
		local $maxReqExpr = shift @vars ;
		local $exaReqExpr = shift @vars ;
		local $numOfGrps = shift @vars ;
		local $numOfGrpVars = shift @vars ;
		local $numOfVars = shift @vars ;
		local $minYesVars = shift @vars ;
		local $maxYesVars = shift @vars ;
		local $gotVars = $#vars + 1 ;
		local $errCnt = 0 ;

		# Check whether the number of variables in @vars is equal to $numOfVars.
		if ($numOfVars != $gotVars)
		{
			&DieMsg ("Fatal Error", "Subroutine RunYesReqRule2 expected " . &HTMLEncodeText ($numOfVars) . " variables but got " . &HTMLEncodeText ($gotVars) . ".", "Please contact this site's webmaster.") ;
		}

		if ($numOfGrps > 0 && $numOfGrpVars > 0 && $numOfVars == $numOfGrps * $numOfGrpVars)
		{
			for (local $ggg = 0; $ggg < $numOfGrps ; $ggg++)
			{
				local $yesVars = 0 ;
				local $misVars = 0 ;

				for (local $vvv = 0; $vvv < $numOfGrpVars ; $vvv++)
				{
					local $varName = $vars[($ggg * $numOfGrpVars) + $vvv] ;

					if (!defined ($insVarValues{$varName}))
					{
						$misVars++ ;
					}
					elsif (defined $ansVarValues{$varName} && $ansVarValues{$varName} == 1)
					{
						$yesVars++ ;
					}
				}

				$errCnt++ if ($misVars < $numOfGrpVars && ($yesVars < $minYesVars || $yesVars > $maxYesVars)) ;
			}

			if ($errCnt > 0)
			{
				local $errExpr ;

				$errExpr = $minMaxReqExpr	if (($minYesVars > 0 && ($minYesVars < $numOfGrpVars && $minYesVars != $maxYesVars)) && ($maxYesVars < $numOfGrpVars)) ;
				$errExpr = $minReqExpr		if (($minYesVars > 0 && ($minYesVars < $numOfGrpVars && $minYesVars != $maxYesVars)) && ($maxYesVars >= $numOfGrpVars)) ;
				$errExpr = $maxReqExpr		if ($minYesVars <= 0) ;
				$errExpr = $exaReqExpr		if (($minYesVars > 0 && ($minYesVars >= $numOfGrpVars || $minYesVars == $maxYesVars))) ;

				local $errMsg = &SafeEval (qq/"$errExpr"/) ;
				if ($@)
				{
					$ret .= $kErrMsgDelimiter if ($ret ne '') ;
					$ret .= "Error" .
							  $kErrMsgDelimiter .
							  "Syntax error in rule message \"".&HTMLEncodeText ($errExpr)."\": $@" .
							  $kErrMsgDelimiter .
							  "Syntax error in rule message \"".&HTMLEncodeText ($errExpr)."\": $@" ;
				}
				else
				{
					$ret .= $kErrMsgDelimiter if ($ret ne '') ;
					$ret .= "Error" .
							  $kErrMsgDelimiter .
							  &HTMLEncodeText ($errMsg) .
							  $kErrMsgDelimiter .
							  &HTMLEncodeText ($errMsg) ;
				}
			}
		}
	}
	return $ret ;
}

# Subroutine RunYesMisRule1
#
# Returns '' when at least M or at most P variables have a yes response.
# Otherwise, returns warning, msg1, msg2 triplets.
#
# Expects 6+N arguments:
#
#     operation
#		G (total number of groups)
#		V (number of variables in each group)
#		N (total number of variables)
#		M (minimum number of variables with answers)
#		P (maximum number of variables with answers)
#     list of N variable names.

sub RunYesMisRule1
{
	local (@para) = @_ ;
	local ($op) = shift @para ;
	unshift (@para, $E_msgRuleExaYesMis) ;
	unshift (@para, $E_msgRuleMaxYesMis) ;
	unshift (@para, $E_msgRuleMinMaxYesMis) ;
	unshift (@para, $E_msgRuleMinYesMis) ;
	unshift (@para, $op) ;
	return &RunYesMisRule2 (@para) ;
}

# Subroutine RunYesMisRule2
#
# Returns '' when at least M or at most P variables have a yes response.
# Otherwise, returns warning, msg1, msg2 triplet.
#
# Expects 10+N arguments:
#
#		operation
#		minimum missing message
#		minimum and maximum missing message
#		maximum missing message
#		exact missing message
#		G (total number of groups)
#		V (number of variables in each group)
#		N (total number of variables)
#		M (minimum number of variables with answers)
#		P (maximum number of variables with answers)
#		list of N variable names.

sub RunYesMisRule2
{
	local $ret = '' ;
	local (@vars) = @_ ;
	local $op = shift @vars ;

	if ($op eq $kSaving)
	{
		local $minMisExpr = shift @vars ;
		local $minMaxMisExpr = shift @vars ;
		local $maxMisExpr = shift @vars ;
		local $exaMisExpr = shift @vars ;
		local $numOfGrps = shift @vars ;
		local $numOfGrpVars = shift @vars ;
		local $numOfVars = shift @vars ;
		local $minYesVars = shift @vars ;
		local $maxYesVars = shift @vars ;
		local $gotVars = $#vars + 1 ;
		local $errCnt = 0 ;

		# Check whether the number of variables in @vars is equal to $numOfVars.
		if ($numOfVars != $gotVars)
		{
			&DieMsg ("Fatal Error", "Subroutine RunYesMisRule2 expected " . &HTMLEncodeText ($numOfVars) . " variables but got " . &HTMLEncodeText ($gotVars) . ".", "Please contact this site's webmaster.") ;
		}

		if ($numOfGrps > 0 && $numOfGrpVars > 0 && $numOfVars == $numOfGrps * $numOfGrpVars)
		{
			for (local $ggg = 0; $ggg < $numOfGrps ; $ggg++)
			{
				local $yesVars = 0 ;
				local $misVars = 0 ;

				for (local $vvv = 0; $vvv < $numOfGrpVars ; $vvv++)
				{
					local $varName = $vars[($ggg * $numOfGrpVars) + $vvv] ;

					if (!defined ($insVarValues{$varName}))
					{
						$misVars++ ;
					}
					elsif (defined $ansVarValues{$varName} && $ansVarValues{$varName} == 1)
					{
						$yesVars++ ;
					}
				}

				$errCnt++ if ($misVars < $numOfGrpVars && ($yesVars < $minYesVars || $yesVars > $maxYesVars)) ;
			}

			if ($errCnt > 0)
			{
				local $errExpr ;

				$errExpr = $minMaxMisExpr	if (($minYesVars > 0 && ($minYesVars < $numOfGrpVars && $minYesVars != $maxYesVars)) && ($maxYesVars < $numOfGrpVars)) ;
				$errExpr = $minMisExpr		if (($minYesVars > 0 && ($minYesVars < $numOfGrpVars && $minYesVars != $maxYesVars)) && ($maxYesVars >= $numOfGrpVars)) ;
				$errExpr = $maxMisExpr		if ($minYesVars <= 0) ;
				$errExpr = $exaMisExpr		if (($minYesVars > 0 && ($minYesVars >= $numOfGrpVars || $minYesVars == $maxYesVars))) ;

				local $errMsg = &SafeEval (qq/"$errExpr"/) ;
				if ($@)
				{
					$ret .= $kErrMsgDelimiter if ($ret ne '') ;
					$ret .= "Error" .
							  $kErrMsgDelimiter .
							  "Syntax error in rule message \"".&HTMLEncodeText ($errExpr)."\": $@" .
							  $kErrMsgDelimiter .
							  "Syntax error in rule message \"".&HTMLEncodeText ($errExpr)."\": $@" ;
				}
				else
				{
					$ret .= $kErrMsgDelimiter if ($ret ne '') ;
					$ret .= "Warning" .
							  $kErrMsgDelimiter .
							  &HTMLEncodeText ($errMsg) .
							  $kErrMsgDelimiter .
							  &HTMLEncodeText ($errMsg) ;
				}
			}
		}
	}
	return $ret ;
}

# Subroutine RunRequiredRule5
#
# Returns '' when at least one variable has a response.
# Otherwise, returns error, msg1, msg2 triplets.
#
# Expects 3+N arguments:
#
#		operation
#		conditional expression
#		N (total number of variables)
#		list of N variable names.

sub RunRequiredRule5
{
	local (@para) = @_ ;
	local $op = shift @para ;
	local $expr = shift @para ;
	local $ret = '' ;
	local $res = &SafeEval (&ExpandShortVarRefs (&TagDecodeText ($expr))) ;
	if ($@)
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" ;
	}
	elsif ($res == 1)
	{
		unshift (@para, $op) ;
		$ret = &RunRequiredRule (@para) ;
	}
	return $ret ;
}

# Subroutine RunRequiredRule6
#
# Returns '' when at least one variable has a response.
# Otherwise, returns error, msg1, msg2 triplet.
#
# Expects 4+N arguments:
#
#		operation
#		expression
#		required message
#		N (total number of variables)
#		list of N variable names.

sub RunRequiredRule6
{
	local (@para) = @_ ;
	local $op = shift @para ;
	local $expr = shift @para ;
	local $ret = '' ;
	local $res = &SafeEval (&ExpandShortVarRefs (&TagDecodeText ($expr))) ;
	if ($@)
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" ;
	}
	elsif ($res == 1)
	{
		unshift (@para, $op) ;
		$ret = &RunRequiredRule2 (@para) ;
	}
	return $ret ;
}

# Subroutine RunRequiredRule7
#
# Returns '' when at least M or at most P variables have a response.
# Otherwise, returns error, msg1, msg2 triplets.
#
# Expects 5+N arguments:
#
#		operation
#		conditional expression
#		N (total number of variables)
#		M (minimum number of variables with answers)
#		P (maximum number of variables with answers)
#		list of N variable names.

sub RunRequiredRule7
{
	local (@para) = @_ ;
	local $op = shift @para ;
	local $expr = shift @para ;
	local $ret = '' ;
	local $res = &SafeEval (&ExpandShortVarRefs (&TagDecodeText ($expr))) ;
	if ($@)
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" ;
	}
	elsif ($res == 1)
	{
		unshift (@para, $op) ;
		$ret = &RunRequiredRule3 (@para) ;
	}
	return $ret ;
}

# Subroutine RunRequiredRule8
#
# Returns '' when at least M or at most P variables have a response.
# Otherwise, returns error, msg1, msg2 triplet.
#
# Expects 10+N arguments:
#
#		operation
#		conditional expression
#		minimum required message
#		minimum and maximum required message
#		maximum required message
#		exact required message
#		all required message
#		N (total number of variables)
#		M (minimum number of variables with answers)
#		P (maximum number of variables with answers)
#		list of N variable names.

sub RunRequiredRule8
{
	local (@para) = @_ ;
	local $op = shift @para ;
	local $expr = shift @para ;
	local $ret = '' ;
	local $res = &SafeEval (&ExpandShortVarRefs (&TagDecodeText ($expr))) ;
	if ($@)
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" ;
	}
	elsif ($res == 1)
	{
		unshift (@para, $op) ;
		$ret = &RunRequiredRule4 (@para) ;
	}
	return $ret ;
}

# Subroutine RunMissingRule5
#
# Returns '' when at least one variable has a response.
# Otherwise, returns warning, msg1, msg2 triplets.
#
# Expects 3+N arguments:
#
#		operation
#		conditional expression
#		N (total number of variables)
#		list of N variable names.

sub RunMissingRule5
{
	local (@para) = @_ ;
	local $op = shift @para ;
	local $expr = shift @para ;
	local $ret = '' ;
	local $res = &SafeEval (&ExpandShortVarRefs (&TagDecodeText ($expr))) ;
	if ($@)
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" ;
	}
	elsif ($res == 1)
	{
		unshift (@para, $op) ;
		$ret = &RunMissingRule (@para) ;
	}
	return $ret ;
}

# Subroutine RunMissingRule6
#
# Returns '' when at least one variable has a response.
# Otherwise, returns warning, msg1, msg2 triplet.
#
# Expects 4+N arguments:
#
#		operation
#		conditional expression
#		missing message
#		N (total number of variables)
#		list of N variable names

sub RunMissingRule6
{
	local (@para) = @_ ;
	local $op = shift @para ;
	local $expr = shift @para ;
	local $ret = '' ;
	local $res = &SafeEval (&ExpandShortVarRefs (&TagDecodeText ($expr))) ;
	if ($@)
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" ;
	}
	elsif ($res == 1)
	{
		unshift (@para, $op) ;
		$ret = &RunMissingRule2 (@para) ;
	}
	return $ret ;
}

# Subroutine RunMissingRule7
#
# Returns '' when at least M or at most P variables have a response.
# Otherwise, returns warning, msg1, msg2 triplets.
#
# Expects 5+N arguments:
#
#		operation
#		conditional expression
#		N (total number of variables)
#		M (minimum number of variables with answers)
#		P (maximum number of variables with answers)
#		list of N variable names.

sub RunMissingRule7
{
	local (@para) = @_ ;
	local $op = shift @para ;
	local $expr = shift @para ;
	local $ret = '' ;
	local $res = &SafeEval (&ExpandShortVarRefs (&TagDecodeText ($expr))) ;
	if ($@)
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" ;
	}
	elsif ($res == 1)
	{
		unshift (@para, $op) ;
		$ret = &RunMissingRule3 (@para) ;
	}
	return $ret ;
}

# Subroutine RunMissingRule8
#
# Returns '' when at least M or at most P variables have a response.
# Otherwise, returns warning, msg1, msg2 triplet.
#
# Expects 10+N arguments:
#
#		operation
#		conditional expression
#		minimum missing message
#		minimum and maximum missing message
#		maximum missing message
#		exact missing message
#		all missing message
#		N (total number of variables)
#		M (minimum number of variables with answers)
#		P (maximum number of variables with answers)
#		list of N variable names.

sub RunMissingRule8
{
	local (@para) = @_ ;
	local $op = shift @para ;
	local $expr = shift @para ;
	local $ret = '' ;
	local $res = &SafeEval (&ExpandShortVarRefs (&TagDecodeText ($expr))) ;
	if ($@)
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" ;
	}
	elsif ($res == 1)
	{
		unshift (@para, $op) ;
		$ret = &RunMissingRule4 (@para) ;
	}
	return $ret ;
}

# Subroutine RunYesReqRule3
#
# Returns '' when at least M or at most P variables have a yes response.
# Otherwise, returns error, msg1, msg2 triplets.
#
# Expects 7+N arguments:
#
#		operation
#		conditional expression
#		G (total number of groups)
#		V (number of variables in each group)
#		N (total number of variables)
#		M (minimum number of variables with answers)
#		P (maximum number of variables with answers)
#		list of N variable names.

sub RunYesReqRule3
{
	local (@para) = @_ ;
	local $op = shift @para ;
	local $expr = shift @para ;
	local $ret = '' ;
	local $res = &SafeEval (&ExpandShortVarRefs (&TagDecodeText ($expr))) ;
	if ($@)
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" ;
	}
	elsif ($res == 1)
	{
		unshift (@para, $op) ;
		$ret = &RunYesReqRule1 (@para) ;
	}
	return $ret ;
}

# Subroutine RunYesReqRule4
#
# Returns '' when at least M or at most P variables have a yes response.
# Otherwise, returns error, msg1, msg2 triplet.
#
# Expects 11+N arguments:
#
#		operation
#		conditional expression
#		minimum required message
#		minimum and maximum required message
#		maximum required message
#		exact required message
#		G (total number of groups)
#		V (number of variables in each group)
#		N (total number of variables)
#		M (minimum number of variables with answers)
#		P (maximum number of variables with answers)
#		list of N variable names.

sub RunYesReqRule4
{
	local (@para) = @_ ;
	local $op = shift @para ;
	local $expr = shift @para ;
	local $ret = '' ;
	local $res = &SafeEval (&ExpandShortVarRefs (&TagDecodeText ($expr))) ;
	if ($@)
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" ;
	}
	elsif ($res == 1)
	{
		unshift (@para, $op) ;
		$ret = &RunYesReqRule2 (@para) ;
	}
	return $ret ;
}

# Subroutine RunYesMisRule3
#
# Returns '' when at least M or at most P variables have a yes response.
# Otherwise, returns warning, msg1, msg2 triplets.
#
# Expects 7+N arguments:
#
#		operation
#		conditional expression
#		G (total number of groups)
#		V (number of variables in each group)
#		N (total number of variables)
#		M (minimum number of variables with answers)
#		P (maximum number of variables with answers)
#		list of N variable names.

sub RunYesMisRule3
{
	local (@para) = @_ ;
	local $op = shift @para ;
	local $expr = shift @para ;
	local $ret = '' ;
	local $res = &SafeEval (&ExpandShortVarRefs (&TagDecodeText ($expr))) ;
	if ($@)
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" ;
	}
	elsif ($res == 1)
	{
		unshift (@para, $op) ;
		$ret = &RunYesMisRule1 (@para) ;
	}
	return $ret ;
}

# Subroutine RunYesMisRule4
#
# Returns '' when at least M or at most P variables have a yes response.
# Otherwise, returns warning, msg1, msg2 triplet.
#
# Expects 11+N arguments:
#
#		operation
#		conditional expression
#		minimum missing message
#		minimum and maximum missing message
#		maximum missing message
#		exact missing message
#		G (total number of groups)
#		V (number of variables in each group)
#		N (total number of variables)
#		M (minimum number of variables with answers)
#		P (maximum number of variables with answers)
#		list of N variable names.

sub RunYesMisRule4
{
	local (@para) = @_ ;
	local $op = shift @para ;
	local $expr = shift @para ;
	local $ret = '' ;
	local $res = &SafeEval (&ExpandShortVarRefs (&TagDecodeText ($expr))) ;
	if ($@)
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" ;
	}
	elsif ($res == 1)
	{
		unshift (@para, $op) ;
		$ret = &RunYesMisRule2 (@para) ;
	}
	return $ret ;
}

# Subroutine RunYesReqRule5
#
# Returns '' when at least M or at most P variables have a yes response.
# Otherwise, returns error, msg1, msg2 triplets.
#
# Expects 7+N arguments:
#
#     operation
#		G (total number of groups)
#		V (total number of variables in each group)
#     Y (number of yes variables in each group)
#		N (total number of variables)
#		M (minimum number of variables with yes answers)
#		P (maximum number of variables with yes answers)
#		list of N variable names.

sub RunYesReqRule5
{
	local (@para) = @_ ;
	local ($op) = shift @para ;
	unshift (@para, $E_msgRuleExaYesReq) ;
	unshift (@para, $E_msgRuleMaxYesReq) ;
	unshift (@para, $E_msgRuleMinMaxYesReq) ;
	unshift (@para, $E_msgRuleMinYesReq) ;
	unshift (@para, $op) ;
	return &RunYesReqRule6 (@para) ;
}

# Subroutine RunYesReqRule6
#
# Returns '' when at least M or at most P variables have a yes response.
# Otherwise, returns error, msg1, msg2 triplet.
#
# Expects 11+N arguments:
#
#		operation
#		minimum required message
#		minimum and maximum required message
#		maximum required message
#		exact required message
#		G (total number of groups)
#		V (total number of variables in each group)
#     Y (number of yes variables in each group)
#		N (total number of variables)
#		M (minimum number of variables with yes answers)
#		P (maximum number of variables with yes answers)
#		list of N variable names.

sub RunYesReqRule6
{
	local $ret = '' ;
	local (@vars) = @_ ;
	local $op = shift @vars ;

	if ($op eq $kSaving)
	{
		local $minReqExpr = shift @vars ;
		local $minMaxReqExpr = shift @vars ;
		local $maxReqExpr = shift @vars ;
		local $exaReqExpr = shift @vars ;
		local $numOfGrps = shift @vars ;
		local $numOfGrpVars = shift @vars ;
		local $numOfGrpYesVars = shift @vars ;
		local $numOfVars = shift @vars ;
		local $minYesVars = shift @vars ;
		local $maxYesVars = shift @vars ;
		local $gotVars = $#vars + 1 ;
		local $errCnt = 0 ;

		# Check whether the number of variables in @vars is equal to $numOfVars.
		if ($numOfVars != $gotVars)
		{
			&DieMsg ("Fatal Error", "Subroutine RunYesReqRule6 expected " . &HTMLEncodeText ($numOfVars) . " variables but got " . &HTMLEncodeText ($gotVars) . ".", "Please contact this site's webmaster.") ;
		}

		if ($numOfGrps > 0 && $numOfGrpVars > 0 && $numOfVars == $numOfGrps * $numOfGrpVars)
		{
			for (local $ggg = 0; $ggg < $numOfGrps ; $ggg++)
			{
				local $yVarsYes = 0 ;
				local $xVarsYes = 0 ;
				local $misVars = 0 ;

				for (local $vvv = 0; $vvv < $numOfGrpVars ; $vvv++)
				{
					local $varName = $vars[($ggg * $numOfGrpVars) + $vvv] ;

					if (!defined ($insVarValues{$varName}))
					{
						$misVars++ ;
					}
					elsif (defined $ansVarValues{$varName} && $ansVarValues{$varName} == 1)
					{
						$yVarsYes++ if ($vvv < $numOfGrpYesVars) ;
						$xVarsYes++ if ($vvv >= $numOfGrpYesVars) ;
					}
				}

				$errCnt++ if ($misVars < $numOfGrpVars && ($xVarsYes == 0 && ($yVarsYes < $minYesVars || $yVarsYes > $maxYesVars))) ;
			}

			if ($errCnt > 0)
			{
				local $errExpr ;

				$errExpr = $minMaxReqExpr	if (($minYesVars > 0 && ($minYesVars < $numOfGrpYesVars && $minYesVars != $maxYesVars)) && ($maxYesVars < $numOfGrpYesVars)) ;
				$errExpr = $minReqExpr		if (($minYesVars > 0 && ($minYesVars < $numOfGrpYesVars && $minYesVars != $maxYesVars)) && ($maxYesVars >= $numOfGrpYesVars)) ;
				$errExpr = $maxReqExpr		if ($minYesVars <= 0) ;
				$errExpr = $exaReqExpr		if (($minYesVars > 0 && ($minYesVars >= $numOfGrpYesVars || $minYesVars == $maxYesVars))) ;

				local $errMsg = &SafeEval (qq/"$errExpr"/) ;
				if ($@)
				{
					$ret .= $kErrMsgDelimiter if ($ret ne '') ;
					$ret .= "Error" .
							  $kErrMsgDelimiter .
							  "Syntax error in rule message \"".&HTMLEncodeText ($errExpr)."\": $@" .
							  $kErrMsgDelimiter .
							  "Syntax error in rule message \"".&HTMLEncodeText ($errExpr)."\": $@" ;
				}
				else
				{
					$ret .= $kErrMsgDelimiter if ($ret ne '') ;
					$ret .= "Error" .
							  $kErrMsgDelimiter .
							  &HTMLEncodeText ($errMsg) .
							  $kErrMsgDelimiter .
							  &HTMLEncodeText ($errMsg) ;
				}
			}
		}
	}
	return $ret ;
}

# Subroutine RunYesReqRule7
#
# Returns '' when at least M or at most P variables have a yes response.
# Otherwise, returns error, msg1, msg2 triplets.
#
# Expects 8+N arguments:
#
#		operation
#		conditional expression
#		G (total number of groups)
#		V (total number of variables in each group)
#     Y (number of yes variables in each group)
#		N (total number of variables)
#		M (minimum number of variables with yes answers)
#		P (maximum number of variables with yes answers)
#		list of N variable names.

sub RunYesReqRule7
{
	local (@para) = @_ ;
	local $op = shift @para ;
	local $expr = shift @para ;
	local $ret = '' ;
	local $res = &SafeEval (&ExpandShortVarRefs (&TagDecodeText ($expr))) ;
	if ($@)
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" ;
	}
	elsif ($res == 1)
	{
		unshift (@para, $op) ;
		$ret = &RunYesReqRule5 (@para) ;
	}
	return $ret ;
}

# Subroutine RunYesReqRule8
#
# Returns '' when at least M or at most P variables have a yes response.
# Otherwise, returns error, msg1, msg2 triplet.
#
# Expects 12+N arguments:
#
#		operation
#		conditional expression
#		minimum required message
#		minimum and maximum required message
#		maximum required message
#		exact required message
#		G (total number of groups)
#		V (total number of variables in each group)
#     Y (number of yes variables in each group)
#		N (total number of variables)
#		M (minimum number of variables with yes answers)
#		P (maximum number of variables with yes answers)
#		list of N variable names.

sub RunYesReqRule8
{
	local (@para) = @_ ;
	local $op = shift @para ;
	local $expr = shift @para ;
	local $ret = '' ;
	local $res = &SafeEval (&ExpandShortVarRefs (&TagDecodeText ($expr))) ;
	if ($@)
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" ;
	}
	elsif ($res == 1)
	{
		unshift (@para, $op) ;
		$ret = &RunYesReqRule6 (@para) ;
	}
	return $ret ;
}

# Subroutine RunYesMisRule5
#
# Returns '' when at least M or at most P variables have a yes response.
# Otherwise, returns warning, msg1, msg2 triplets.
#
# Expects 7+N arguments:
#
#     operation
#		G (total number of groups)
#		V (total number of variables in each group)
#     Y (number of yes variables in each group)
#		N (total number of variables)
#		M (minimum number of variables with yes answers)
#		P (maximum number of variables with yes answers)
#		list of N variable names.

sub RunYesMisRule5
{
	local (@para) = @_ ;
	local ($op) = shift @para ;
	unshift (@para, $E_msgRuleExaYesReq) ;
	unshift (@para, $E_msgRuleMaxYesReq) ;
	unshift (@para, $E_msgRuleMinMaxYesReq) ;
	unshift (@para, $E_msgRuleMinYesReq) ;
	unshift (@para, $op) ;
	return &RunYesMisRule6 (@para) ;
}

# Subroutine RunYesMisRule6
#
# Returns '' when at least M or at most P variables have a yes response.
# Otherwise, returns warning, msg1, msg2 triplet.
#
# Expects 11+N arguments:
#
#		operation
#		minimum required message
#		minimum and maximum required message
#		maximum required message
#		exact required message
#		G (total number of groups)
#		V (total number of variables in each group)
#     Y (number of yes variables in each group)
#		N (total number of variables)
#		M (minimum number of variables with yes answers)
#		P (maximum number of variables with yes answers)
#		list of N variable names.

sub RunYesMisRule6
{
	local $ret = '' ;
	local (@vars) = @_ ;
	local $op = shift @vars ;

	if ($op eq $kSaving)
	{
		local $minReqExpr = shift @vars ;
		local $minMaxReqExpr = shift @vars ;
		local $maxReqExpr = shift @vars ;
		local $exaReqExpr = shift @vars ;
		local $numOfGrps = shift @vars ;
		local $numOfGrpVars = shift @vars ;
		local $numOfGrpYesVars = shift @vars ;
		local $numOfVars = shift @vars ;
		local $minYesVars = shift @vars ;
		local $maxYesVars = shift @vars ;
		local $gotVars = $#vars + 1 ;
		local $errCnt = 0 ;

		# Check whether the number of variables in @vars is equal to $numOfVars.
		if ($numOfVars != $gotVars)
		{
			&DieMsg ("Fatal Error", "Subroutine RunYesMisRule6 expected " . &HTMLEncodeText ($numOfVars) . " variables but got " . &HTMLEncodeText ($gotVars) . ".", "Please contact this site's webmaster.") ;
		}

		if ($numOfGrps > 0 && $numOfGrpVars > 0 && $numOfVars == $numOfGrps * $numOfGrpVars)
		{
			for (local $ggg = 0; $ggg < $numOfGrps ; $ggg++)
			{
				local $yVarsYes = 0 ;
				local $xVarsYes = 0 ;
				local $misVars = 0 ;

				for (local $vvv = 0; $vvv < $numOfGrpVars ; $vvv++)
				{
					local $varName = $vars[($ggg * $numOfGrpVars) + $vvv] ;

					if (!defined ($insVarValues{$varName}))
					{
						$misVars++ ;
					}
					elsif (defined $ansVarValues{$varName} && $ansVarValues{$varName} == 1)
					{
						$yVarsYes++ if ($vvv < $numOfGrpYesVars) ;
						$xVarsYes++ if ($vvv >= $numOfGrpYesVars) ;
					}
				}

				$errCnt++ if ($misVars < $numOfGrpVars && ($xVarsYes == 0 && ($yVarsYes < $minYesVars || $yVarsYes > $maxYesVars))) ;
			}

			if ($errCnt > 0)
			{
				local $errExpr ;

				$errExpr = $minMaxReqExpr	if (($minYesVars > 0 && ($minYesVars < $numOfGrpYesVars && $minYesVars != $maxYesVars)) && ($maxYesVars < $numOfGrpYesVars)) ;
				$errExpr = $minReqExpr		if (($minYesVars > 0 && ($minYesVars < $numOfGrpYesVars && $minYesVars != $maxYesVars)) && ($maxYesVars >= $numOfGrpYesVars)) ;
				$errExpr = $maxReqExpr		if ($minYesVars <= 0) ;
				$errExpr = $exaReqExpr		if (($minYesVars > 0 && ($minYesVars >= $numOfGrpYesVars || $minYesVars == $maxYesVars))) ;

				local $errMsg = &SafeEval (qq/"$errExpr"/) ;
				if ($@)
				{
					$ret .= $kErrMsgDelimiter if ($ret ne '') ;
					$ret .= "Error" .
							  $kErrMsgDelimiter .
							  "Syntax error in rule message \"".&HTMLEncodeText ($errExpr)."\": $@" .
							  $kErrMsgDelimiter .
							  "Syntax error in rule message \"".&HTMLEncodeText ($errExpr)."\": $@" ;
				}
				else
				{
					$ret .= $kErrMsgDelimiter if ($ret ne '') ;
					$ret .= "Warning" .
							  $kErrMsgDelimiter .
							  &HTMLEncodeText ($errMsg) .
							  $kErrMsgDelimiter .
							  &HTMLEncodeText ($errMsg) ;
				}
			}
		}
	}
	return $ret ;
}

# Subroutine RunYesMisRule7
#
# Returns '' when at least M or at most P variables have a yes response.
# Otherwise, returns warning, msg1, msg2 triplets.
#
# Expects 8+N arguments:
#
#		operation
#		conditional expression
#		G (total number of groups)
#		V (total number of variables in each group)
#     Y (number of yes variables in each group)
#		N (total number of variables)
#		M (minimum number of variables with yes answers)
#		P (maximum number of variables with yes answers)
#		list of N variable names.

sub RunYesMisRule7
{
	local (@para) = @_ ;
	local $op = shift @para ;
	local $expr = shift @para ;
	local $ret = '' ;
	local $res = &SafeEval (&ExpandShortVarRefs (&TagDecodeText ($expr))) ;
	if ($@)
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" ;
	}
	elsif ($res == 1)
	{
		unshift (@para, $op) ;
		$ret = &RunYesMisRule5 (@para) ;
	}
	return $ret ;
}

# Subroutine RunYesMisRule8
#
# Returns '' when at least M or at most P variables have a yes response.
# Otherwise, returns warning, msg1, msg2 triplet.
#
# Expects 12+N arguments:
#
#		operation
#		conditional expression
#		minimum required message
#		minimum and maximum required message
#		maximum required message
#		exact required message
#		G (total number of groups)
#		V (total number of variables in each group)
#     Y (number of yes variables in each group)
#		N (total number of variables)
#		M (minimum number of variables with yes answers)
#		P (maximum number of variables with yes answers)
#		list of N variable names.

sub RunYesMisRule8
{
	local (@para) = @_ ;
	local $op = shift @para ;
	local $expr = shift @para ;
	local $ret = '' ;
	local $res = &SafeEval (&ExpandShortVarRefs (&TagDecodeText ($expr))) ;
	if ($@)
	{
		$ret = "Error" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" .
				 $kErrMsgDelimiter .
				 "Syntax error in rule \"".&HTMLEncodeText (&TagDecodeText ($expr))."\": $@" ;
	}
	elsif ($res == 1)
	{
		unshift (@para, $op) ;
		$ret = &RunYesMisRule6 (@para) ;
	}
	return $ret ;
}

# Subroutine RunRules
#
# Applies rules to the data in %ansVarValues.
#
# If any rule is violated, $warnings and/or $errors are prepared for     
# warning or error HTML page. RunRules returns 'Success' if there is   
# no violation in rules, returns 'Warnings' if there is no fatal error
# and 'Errors' if there is at least one fatal error.

sub RunRules
{
	local ($op) = $_[0] ;
	local ($wrnCnt) = 0 ;
	local ($errCnt) = 0 ;
	local ($result) = '' ;

	foreach $key (keys %rules)
	{
		local ($para) = $rules{$key} ;
		local (@para) = split(/,/, $para) ;
		local ($type) = shift @para ;
		unshift (@para, $op) ;
		local ($subRef) = pop @para ;
		local ($qstnTxt) = pop @para ;
		local ($res) = '' ;

		# Run the appropriate rule
		{
			$res = &RunNumberRule (@para), last if ($type == 1) ;
			$res = &RunRangeRule (@para), last if ($type == 2) ;
			$res = &RunRankRule (@para), last if ($type == 3) ;
			$res = &RunCSumRule (@para), last if ($type == 4) ;
			$res = &RunRequiredRule (@para), last if ($type == 5) ;
			$res = &RunMissingRule (@para), last if ($type == 6) ;
			$res = &RunLimitSubmitsRule (@para), last if ($type == 7) ;
			$res = &RunLimitRespondentsRule (@para), last if ($type == 8) ;
			$res = &RunEnterKeyDoesNotSubmitRule (@para), last if ($type == 9) ;
			$res = &RunAuthorizationRule (@para), last if ($type == 10) ;
			$res = &RunExprRule (@para), last if ($type == 11) ;
			$res = &RunNumberRule2 (@para), last if ($type == 12) ;
			$res = &RunRangeRule2 (@para), last if ($type == 13) ;
			$res = &RunRankRule2 (@para), last if ($type == 14) ;
			$res = &RunCSumRule2 (@para), last if ($type == 15) ;
			$res = &RunRequiredRule2 (@para), last if ($type == 16) ;
			$res = &RunMissingRule2 (@para), last if ($type == 17) ;
			$res = &RunRequiredRule3 (@para), last if ($type == 18) ;
			$res = &RunRequiredRule4 (@para), last if ($type == 19) ;
			$res = &RunMissingRule3 (@para), last if ($type == 20) ;
			$res = &RunMissingRule4 (@para), last if ($type == 21) ;
			$res = &RunExpr2Rule (@para), last if ($type == 22) ;
			$res = &RunYesReqRule1 (@para), last if ($type == 23) ;
			$res = &RunYesReqRule2 (@para), last if ($type == 24) ;
			$res = &RunYesMisRule1 (@para), last if ($type == 25) ;
			$res = &RunYesMisRule2 (@para), last if ($type == 26) ;
			$res = &RunRequiredRule5 (@para), last if ($type == 27) ;
			$res = &RunRequiredRule6 (@para), last if ($type == 28) ;
			$res = &RunRequiredRule7 (@para), last if ($type == 29) ;
			$res = &RunRequiredRule8 (@para), last if ($type == 30) ;
			$res = &RunMissingRule5 (@para), last if ($type == 31) ;
			$res = &RunMissingRule6 (@para), last if ($type == 32) ;
			$res = &RunMissingRule7 (@para), last if ($type == 33) ;
			$res = &RunMissingRule8 (@para), last if ($type == 34) ;
			$res = &RunYesReqRule3 (@para), last if ($type == 35) ;
			$res = &RunYesReqRule4 (@para), last if ($type == 36) ;
			$res = &RunYesMisRule3 (@para), last if ($type == 37) ;
			$res = &RunYesMisRule4 (@para), last if ($type == 38) ;
			$res = &RunYesReqRule5 (@para), last if ($type == 39) ;
			$res = &RunYesReqRule6 (@para), last if ($type == 40) ;
			$res = &RunYesReqRule7 (@para), last if ($type == 41) ;
			$res = &RunYesReqRule8 (@para), last if ($type == 42) ;
			$res = &RunYesMisRule5 (@para), last if ($type == 43) ;
			$res = &RunYesMisRule6 (@para), last if ($type == 44) ;
			$res = &RunYesMisRule7 (@para), last if ($type == 45) ;
			$res = &RunYesMisRule8 (@para), last if ($type == 46) ;
		}

		if ($res ne '')
		{
			($errCnt, $wrnCnt) = FormatRuleResult ($res, $errCnt, $wrnCnt, $qstnTxt, $subRef) ;
		}
	}

	if ($errCnt == 0 && $wrnCnt > 0)
	{
		$result = "Warnings" ;
	}
	elsif ($errCnt > 0)
	{
		$result = "Errors" ;
	}  
	elsif ($errCnt == 0 && $wrnCnt == 0)
	{
		$result = "Success" ;
	}
	return $result ;
}

# Subroutine FormatRuleResult
#
# Formats the error or warning messages and adds them to the %rulErrs or %rulWrns
# associative arrays.

sub FormatRuleResult
{
	local ($res) = $_[0] ;
	local ($errCnt) = $_[1] ;
	local ($wrnCnt) = $_[2] ;
	local ($qstnTxt) = $_[3] ;
	local ($subRef) = $_[4] ;

	if ($res ne '')
	{
		local(@resLst) = split (/$kErrMsgDelimiter/, $res) ;
		local($resCnt) = int (($#resLst + 1) / 3) ;

		for (local ($iii) = 0; $iii < $resCnt ; $iii++)
		{
			local($resTyp) = shift @resLst ;
			local($resMsg1) = shift @resLst ;
			local($resMsg2) = shift @resLst ;
			local($msg) = $resMsg1 ;

			if ($qstnTxt eq '' || $qstnTxt eq '?')
			{
				$msg = $resMsg1 ;
			}
			else
			{
				$msg = "$resMsg2 See \"$qstnTxt\"" ;
			}
			
			if ($resTyp eq "Error")
			{
				$errCnt++ ;
				if (defined ($rulErrs{$subRef}))
				{
					$rulErrs{$subRef} .= "<B><I>$E_errorPrefix $msg</I></B><BR>" ;
				}
				else
				{
					$rulErrs{$subRef} = "<B><I>$E_errorPrefix $msg</I></B><BR>" ;
				}
			}
			elsif ($resTyp eq "Warning")
			{
				$wrnCnt++ ;
				if (defined ($rulWrns{$subRef}))
				{
					$rulWrns{$subRef} .= "<B><I>$E_warningPrefix $msg</I></B><BR>" ;
				}
				else
				{
					$rulWrns{$subRef} = "<B><I>$E_warningPrefix $msg</I></B><BR>" ;
				}
			}
		}
	}
	
	return ($errCnt, $wrnCnt) ;
}

# Subroutine PageRule_ShowOrHideMarkedTextBlocks
#
# Shows or hides marked blocks of text depending on the result
# of evaluating an expression in the rule definition.
# Returns the modified page.

sub PageRule_ShowOrHideMarkedTextBlocks
{
	local $page = $_[0] ;
	local ($type, $name, $expr, $count) = split(/,/, $_[1]) ;
	local $result = &SafeEval (&ExpandShortVarRefs ($expr)) ;
	if ($@)
	{
		&DieMsg ("Fatal Error", "Error in \"" . &HTMLEncodeText ($name) . "\" expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
	}
	elsif ($result != 1)
	{
		# Remove the blocks of text
		for (local ($iii) = 0; $iii < $count; $iii++)
		{
			local ($pattern) = '<!--\s*' . $name . '_' . $iii . '\s*-->(.*?)<!--\s*' . $name . '_' . $iii . '\s*-->' ;
			local ($r) =  '<!-- ' . $name . '_' . $iii . ' -->' . '<!-- ' . $name . '_' . $iii . ' -->' ;
			$page =~ s/$pattern/$r/si ;  # Remove the block of text between the markers
			# Commenting the block does not work if the text block itself contains comments
		}
	}

	return $page ;
}

# Subroutine ArrayShuffle
#
# Generates a random permutation of the array in place. Uses
# Fisher-Yates algorithm.

sub ArrayShuffle
{
	my ($array) = shift;
	for (my $iii = @$array; --$iii; )
	{
		my $jjj = int rand ($iii + 1) ;
		next if $iii == $jjj ;
		@$array[$iii,$jjj] = @$array[$jjj,$iii];
	}
}

# Subroutine GetNewShuffledOrder
#
# Returns a comma separated list of randomly ordered numbers given a
# start and stop range.

sub GetNewShuffledOrder
{
	local ($start) = $_[0] ;
	local ($stop) = $_[1] ;

	local (@r) = ();
	if ($stop >= $start)
	{
		# Create an array to shuffle
		{
			for (local ($iii) = 0; $iii <= ($stop - $start); $iii++)
			{
				$r[$iii] = $start + $iii ;
			}
		}
		# Shuffle the array in place
		ArrayShuffle (\@r) ;

		# Prepend the array with numbers leading to start
		{
			for (local ($iii) = 0; $iii < $start; $iii++)
			{
				unshift (@r, $start - $iii - 1) ;
			}
		}
	}
	return join (',', @r);
}

# Subroutine PageRule_ShuffleMarkedTextBlocks
#
# Randomly shuffles blocks of text.
# Returns the modified page.

sub PageRule_ShuffleMarkedTextBlocks
{
	local ($page) = $_[0] ;
	local ($type, $name, $start, $stop, $count) = split(/,/, $_[1]) ;

	if ($stop > $start)
	{
		# Has the new order already been determined?
		if (!defined ($globalFields{$name}))
		{
			# Get the new shuffled order of the marked text blocks
			$globalFields{$name} = &GetNewShuffledOrder ($start, $stop) ;
		}

		# Turn the list into an array
		local (@order) = split(/,/,$globalFields{$name});

		for (local ($jjj) = 0; $jjj < $count; $jjj++)
		{
			local (@text) = () ;
			# Find and store all blocks of text that are going to be moved
			{
				for (local ($iii) = $start; $iii <= $stop; $iii++)
				{
					if ($order[$iii] != $iii)			# Only find blocks of text that are going to be moved
					{
						local ($pattern) = '<!--\s*' . $name . '_' . $iii . '_' . $jjj . '\s*-->(.*?)<!--\s*' . $name . '_' . $iii . '_' . $jjj . '\s*-->' ;
						if ($page =~ m/$pattern/si)	# Use markers to find the block of text
						{
							$text[$iii] = $1 ;			# Store the block of text without the markers
						}
					}
				}
			}

#			&DieMsg ("|$globalFields{$name}|", @text, "1" );
			# Put the blocks of text in their new locations
			{
				for (local ($iii) = $start; $iii <= $stop; $iii++)
				{
					if ($order[$iii] != $iii)			# Only replace blocks of text that are going to be moved
					{
						local ($pattern) = '<!--\s*' . $name . '_' . $iii . '_' . $jjj. '\s*-->(.*?)<!--\s*' . $name . '_' . $iii . '_' . $jjj . '\s*-->' ;
						local ($r) =  '<!-- ' . $name . '_' . $iii . '_' . $jjj . ' -->' . $text[$order[$iii]] . '<!-- ' . $name . '_' . $iii . '_' . $jjj . ' -->' ;
						$page =~ s/$pattern/$r/si ;  # Replace the markers and original block of text with the same markers and the new block of text
					}
				}
			}
		}
	}

	return $page ;
}

# Subroutine PageRule_ShowMaxMarkedTextBlocks
#
# Shows or hides marked blocks of text depending on the result
# of evaluating expressions in the rule definition. Shows a specified
# maximum number of blocks. Returns the modified page.

sub PageRule_ShowMaxMarkedTextBlocks
{
	local ($page) = $_[0] ;
	local (@rule) = split (/,/, $_[1]) ;
	local ($ruleType) = shift @rule ;
	local ($ruleName) = shift @rule ;
	local ($rulePairs) = shift @rule ;
	local ($ruleMax) = shift @rule ;
	local ($ruleCount) = shift @rule ;

	local (@showList) = () ;
	local (@hideList) = () ;

	# Determine which blocks to show or hide
	{
		for (local ($iii) = 0; $iii < $rulePairs; $iii++)
		{
			local $name = shift @rule ;
			local $expr = shift @rule ;
			local $result = &SafeEval (&ExpandShortVarRefs ($expr)) ;
			if ($@)
			{
				&DieMsg ("Fatal Error", "Error in \"" . &HTMLEncodeText ($name) . "\" expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
			}
			elsif ($result != 1)
			{
				# Add to the hide list
				push (@hideList, $name) ;
			}
			else
			{
				# Add to the show list
				push (@showList, $name) ;
			}
		}
	}

	# Is the result the same as before?
	if (!defined ($globalFields{$ruleName . "_0"}) || !defined ($globalFields{$ruleName . "_1"}) || $globalFields{$ruleName . "_0"} ne join (',', @showList))
	{
		# Store the new or updated result
		$globalFields{$ruleName . "_0"} = join (',', @showList);

		if ($#showList + 1 > $ruleMax)
		{
			# Randomly select extra entries to hide
			# Shuffle the array in place
			ArrayShuffle (\@showList) ;

			# Move extra entries to the hide list
			local ($moveCount) = $#showList + 1 - $ruleMax;
			for (local ($iii) = 0; $iii < $moveCount; $iii++)
			{
				# Move entry from the show list to the hide list
				push (@hideList, shift @showList) ;
			}
		}

		# Store the new or updated result
		$globalFields{$ruleName . "_1"} = join (',', @hideList);
	}
	else
	{
		@hideList = split (/,/, $globalFields{$ruleName . "_1"}) ;
	}

	# Remove the blocks of text
	{
		for (local ($iii) = 0; $iii <= $#hideList; $iii++)
		{
			for (local ($jjj) = 0; $jjj < $ruleCount; $jjj++)
			{
				local ($name) = $hideList[$iii] ;
				local ($pattern) = '<!--\s*' . $name . '_' . $jjj . '\s*-->(.*?)<!--\s*' . $name . '_' . $jjj . '\s*-->' ;
				local ($r) =  '<!-- ' . $name . '_' . $jjj . ' -->' . '<!-- ' . $name . '_' . $jjj . ' -->' ;
				$page =~ s/$pattern/$r/si ;  # Remove the block of text between the markers
				# Commenting the block does not work if the text block itself contains comments
			}
		}
	}

	return $page ;
}

# Subroutine RunPageRules
#
# Runs the page rules in the %pageRules associative array.
# Returns the modified source string.

sub RunPageRules
{
	local ($page) = $_[0] ;

	foreach $key (keys %pageRules)
	{
		local ($para) = $pageRules{$key} ;
		local (@para) = split(/,/, $para) ;
		local ($type) = shift @para ;

		# Run the appropriate page rule
		{
			$page = &PageRule_ShowOrHideMarkedTextBlocks ($page, $pageRules{$key}), last if ($type == 1) ;
			$page = &PageRule_ShuffleMarkedTextBlocks ($page, $pageRules{$key}), last if ($type == 2) ;
			$page = &PageRule_ShowMaxMarkedTextBlocks ($page, $pageRules{$key}), last if ($type == 3) ;
		}
	}
	
	return $page ;
}

# Subroutine URLEncodeVarRefs
#
# Replaces references to variables using $ + variable name with the
# encoded value of the variable in the %varValues associative array.

sub URLEncodeVarRefs
{
	local $refs = $_[0] ;

	local $pattern = '\$\w+' ;								# Search for all occurrences of $name
	local (@matchList) = ($refs =~ m/$pattern/gi) ;	# Store search results in an array
	for (local $iii = 0; $iii < $#matchList + 1; $iii++)
	{
		local $name = substr ($matchList[$iii], 1) ;	# Extract the variable name
		local $pos = &GetVarListPos ($name) ;			# Is the variable in the list?
		if ($pos >= 0)
		{
			local $value = &URLEncodeText ($varValues{$name}) ;
			$pattern = quotemeta ($matchList[$iii]) ;
			$refs =~ s/$pattern/$value/i ;
		}
	}

	return $refs ;
}

# Subroutine URLEncodeText
#
# Returns an URL encoded version of the given text.

sub URLEncodeText
{
	local $enc = $_[0] ;

	# Some characters need to be encoded
	$enc =~ s/%/$kCodePercent/ge ;		# Replace % with %25

	# Encode the others
	$enc =~ s/ /$kCodeSpace/ge ;			# Replace space with %20
	$enc =~ s/"/$kCodeDblQuote/ge ;		# Replace " with %22
	$enc =~ s/#/$kCodeHash/ge ;			# Replace # with %23
	$enc =~ s/&/$kCodeAmpersand/ge ;		# Replace & with %26
	$enc =~ s/\+/$kCodePlus/ge ;			# Replace + with %2B
#	$enc =~ s/\//$kCodeFwdSlash/ge ;		# Replace / with %2F
#	$enc =~ s/:/$kCodeColon/ge ;			# Replace : with %3A
	$enc =~ s/;/$kCodeSemicolon/ge ;		# Replace ; with %3B
	$enc =~ s/</$kCodeLT/ge ;				# Replace < with %3C
	$enc =~ s/=/$kCodeEquals/ge ;			# Replace = with %3D
	$enc =~ s/>/$kCodeGT/ge ;				# Replace > with %3E
	$enc =~ s/\?/$kCodeQstn/ge ;			# Replace ? with %3F

	return $enc ;
}

# Subroutine HTMLEncodeText
#
# Returns an HTML encoded version of the given text.

sub HTMLEncodeText
{
	local $enc = $_[0] ;

	# Encode the named entities
	$enc =~ s/\&/&amp;/g ;					# Replace & with &amp;
#	$enc =~ s/ /&nbsp;/g ;					# Replace space with &nbsp;
	$enc =~ s/"/&quot;/g ;					# Replace " with &quot;
	$enc =~ s/</&lt;/g ;						# Replace < with &lt;
	$enc =~ s/>/&gt;/g ;						# Replace > with &gt;

	return $enc ;
}

# Subroutine TagEncodeText
#
# Returns an tag encoded version of the given text.

sub TagEncodeText
{
	local $enc = $_[0] ;

	# Encode the characters
	$enc =~ s/%/$kCodePercent/ge ;		# Replace % with %25
	$enc =~ s/\r/$kCodeCR/ge ;				# Replace \r with %0D
	$enc =~ s/\n/$kCodeNL/ge ;				# Replace \n with %0A
	$enc =~ s/,/$kCodeComma/ge ;			# Replace , with %2C
	$enc =~ s/>/$kCodeGT/ge ;				# Replace > with %3E
	$enc =~ s/</$kCodeLT/ge ;				# Replace < with %3C
	$enc =~ s/"/$kCodeDblQuote/ge ;		# Replace " with %22

	return $enc ;
}

# Subroutine TagDecodeText
#
# Returns an tag decoded version of the given text.

sub TagDecodeText
{
	local $dec = $_[0] ;

	# Decode the characters
	$dec =~ s/$kCodeDblQuote/"/g ;		# Replace %22 with "
	$dec =~ s/$kCodeLT/</g ;				# Replace %3C with <
	$dec =~ s/$kCodeGT/>/g ;				# Replace %3E with >
	$dec =~ s/$kCodeComma/,/g ;			# Replace %2C with ,
	$dec =~ s/$kCodeNL/\n/g ;				# Replace %0A with \n
	$dec =~ s/$kCodeCR/\r/g ;				# Replace %0D with \r
	$dec =~ s/$kCodePercent/\r/g ;		# Replace %25 with %

	return $dec ;
}

# Subroutine CreateSuccessPage
#
# Checks whether environment variables exist and then
# redirects or outputs the success HTML page.

sub CreateSuccessPage
{
	local $page = '';

	if (!defined $raw_data{'E_displayWebPage'} )
	{
		&DieMsg("Fatal Error", "The script cannot process your survey because ".
				  "the Web survey's hidden field E_displayWebPage is missing.",
    			  "Please contact this site's webmaster.") ;
	}          
	else
	{
		if ($raw_data{'E_displayWebPage'} eq 'Yes')
		{
			if (!defined $raw_data{'E_urlWebPage'} )
			{
				&DieMsg("Fatal Error", "The script cannot process your survey because ".
						  "the Web survey's hidden field E_urlWebPage is missing.",
						  "Please contact this site's webmaster.") ;
			}
			$page = &GetLocationRedirect (&URLEncodeVarRefs ($raw_data{'E_urlWebPage'})) ;
		}      
		elsif ($raw_data{'E_displayWebPage'} eq 'No')
		{ 
			if (!defined $raw_data{'E_sucMessage'} )
			{
				&DieMsg("Fatal Error", "The script cannot process your survey because ".
						  "the Web survey's hidden field E_sucMessage is missing.",
						  "Please contact this site's webmaster.") ;
			}
			if (!defined $raw_data{'E_includeHyperlink'} )
			{
				&DieMsg("Fatal Error", "The script cannot process your survey because ".
						  "the Web survey's hidden field E_includeHyperlink is missing.",
						  "Please contact this site's webmaster.") ;
			}
			else
			{
				if ($raw_data{'E_includeHyperlink'} eq 'Yes' )
				{
					if (!defined $raw_data{'E_hyperlinkText'} )
					{
						&DieMsg("Fatal Error", "The script cannot process your survey because ".
								  "the Web survey's hidden field E_hyperlinkText is missing.",
								  "Please contact this site's webmaster.") ;
					}
					if (!defined $raw_data{'E_hyperlinkUrl'} )
					{
						&DieMsg("Fatal Error", "The script cannot process your survey because ".
								  "the Web survey's hidden field E_hyperlinkUrl is missing.",
								  "Please contact this site's webmaster.") ;
					}
					$page = &GetContentTypeHTML () .
							  "<html><body><h2>".$raw_data{'E_sucMessage'}.
							  "</h2>\n<p>".
							  "<A Href=\"" . &URLEncodeVarRefs ($raw_data{'E_hyperlinkUrl'}) . "\">".
							  $raw_data{'E_hyperlinkText'}."</A>\n".
							  "</body></html>" ;
				}
				elsif ($raw_data{'E_includeHyperlink'} eq 'No' )
				{
					$page = &GetContentTypeHTML () .
							  "<html><body><h2>".$raw_data{'E_sucMessage'}.
							  "</h2>\n<p>\n".
							  "</body></html>" ;
				}
				else
				{
					&DieMsg("Fatal Error", "The script cannot process your survey because ".
							  "the Web survey's hidden field E_includeHyperlink is neither Yes nor No.",
							  "Please contact this site's webmaster.") ;
				}
			}
		}
		else
		{
			&DieMsg("Fatal Error", "The script cannot process your survey because ".
					  "the Web survey's hidden field E_displayWebPage is neither Yes nor No.", 
					  "Please contact this site's webmaster.") ;
		}
	}
	return $page ;
}

# Subroutine MergeVarValues
#
# Merges the data in %ansVarValues, %evlVarValues, %fwdVarValues, %recVarValues and
# %defVarValues into @varValues and %varValues.

sub MergeVarValues
{
	for (local ($iii) = 0 ; $iii <= $#varList; $iii++)
	{
		local ($value) = '' ;
		local ($varName) = $varList[$iii] ;
		if (defined ($ansVarValues{$varName}))
		{
			$value = $ansVarValues{$varName} ;
		}
		elsif (defined ($evlVarValues{$varName}))
		{
			$value = $evlVarValues{$varName} ;
		}
		elsif (defined ($insVarValues{$varName}))
		{
			if (defined ($defVarValues{$varName}))
			{
				$value = $defVarValues{$varName} ;
			}
		}
		elsif (defined ($fwdVarValues{$varName}))
		{
			$value = $fwdVarValues{$varName} ;
		}
		elsif (defined ($recVarValues{$varName}))
		{
			$value = $recVarValues{$varName} ;
		}

		$varValues[$iii] = $value ;
		$varValues{$varName} = $value ;
	}
	1; #return true
}

# Subroutine PrepareVarValues
#
# Prepares the values in varValues for writing to a file.

sub PrepareVarValues
{
	for (local ($iii) = 0; $iii <= $#varList; $iii++)
	{
		$value = $varValues[$iii] ;

		if ($value ne '')
		{
			$value =~ s/"/""/g ;					# Replace double quotes with two
			$_ = $value ;
			local ($cntComma) = tr/,/,/ ;  	# Count the number of commas
			local ($cntQuote) = tr/"/"/ ;  	# Count the number of double quotes

			if ($cntComma != 0 || $cntQuote != 0)
			{
				$value = "\"".$value."\"" ;	# Enclose the value in double quotes
			}
			$varValues[$iii] = $value ;
		}
	}
}

# Subroutine WriteDataFile
#
# Writes data to the given path.
#
# If the file does not currently exist, the subroutine
#    creates a file
#    writes in the first row all the variable names, and
#    writes the corresponding values of the variables to the second row.
#
# If the file already exists the subroutine appends the values of the
# variables at the end or modifies the file given variable settings
# found in the %qryVarValue associative array.

sub WriteDataFile
{
	local $path = $_[0] ;
	local ($lockHandle, $lockPath, $lockMode) = &LockFile ($path, 2) ;	# Wait for an exclusive lock
	local $pathExists = &CheckPathExists ($path) ;
	local $writeVarList = "false" ;

	if ($pathExists eq "true")
	{
		# Check the variable list in the data file
		local ($vlst) = join (',', @varList);
		$writeVarList = "true" if (&CheckDataFile ($path, $vlst) eq "empty") ;
	}

	if ($pathExists ne "true" || $writeVarList eq "true")
	{
		if ($bCreateDataFile eq "Yes")
		{
			&CreateDataFile ($path) ;
		}
		elsif ($pathExists ne "true")
		{
			&DieMsg ("Fatal Error",
						"The script cannot process your survey because ".
						"the data file (" . &HTMLEncodeText ($path) . ") does not exist.",
						"Please contact this site's webmaster.") ;
		}
		else
		{
			&DieMsg ("Fatal Error",
						"The script cannot process your survey because ".
						"the data file (" . &HTMLEncodeText ($path) . ") is empty.",
						"Please contact this site's webmaster.") ;
		}
	}
	else
	{
		&PerformTest1_1of2 ($path) if ($E_test & 1) ;	# Perform the 1st part of test 1?

		local (@qryVars) = keys %qryVarValues ;
		if ($#qryVars >= 0)
		{
			&ModifyDataFile ($path) ;
		}
		else
		{
			&AppendDataFile ($path) ;
		}
		&PerformTest1_2of2 ($path) if ($E_test & 1) ;	# Perform the 2nd part of test 1?
	}
	&UnlockFile ($lockHandle, $lockPath, $lockMode) ;		# Always release the exclusive lock

	return (0) ;
}

# Subroutine CreateDataFile
#
# Creates the given data file. Writes in the first row all of the
# variable names and writes the corresponding values of the variables
# in the second row.

sub CreateDataFile
{
	local ($path) = $_[0] ;
	local ($fileHandle) = $path ;

	# Open the data file for writing
	if (open ($fileHandle, ">$path"))
	{
		$,= ',' ;													# Comma delimited
		print ($fileHandle @varList) || &DieMsg () ;		# Write the variable name list
		print ($fileHandle "\n") || &DieMsg ();			# Add a newline

		# Write the data
		print ($fileHandle @varValues) || &DieMsg ();	# Write the variable value list
		print ($fileHandle "\n") || &DieMsg ();			# Add a newline

		close ($fileHandle) ;									# Close file and release lock
	}
	elsif (&CheckPathExists ($path) eq "true")
	{
		&DieMsg ("Fatal Error",
					"The script cannot process your survey because ".
					"it cannot write to the data file (" . &HTMLEncodeText ($path) . "): $! ($?). ",
					"If this continues, please contact this site's webmaster.") ;
	}
	else
	{
		&DieMsg ("Fatal Error",
					"The script cannot process your survey because ".
					"it cannot create the data file (" . &HTMLEncodeText ($path) . ") on this server: $! ($?).",
					"Please contact this site's webmaster.") ;
	}

	1 ; # return true
}

# Subroutine ModifyDataFile
#
# Modifies an existing record in the data file if a match is found
# using the %qryVarValues associative array.

sub ModifyDataFile
{
	local $path = $_[0] ;
	local $fileHandle = $path ;

	# Open the data file for reading and writing
	if (open ($fileHandle, "+<$path"))
	{
		local $bFound = 'false' ;

		# Load the data file into an array
		local (@recArray) = () ;
		while (defined ($_ = <$fileHandle>))	# Read the next record
		{
			push (@recArray, $_) ;					# Add to the array
		}

		# Determine if a match has been found using %qryVarValues
		{
			local (@qryVarValueKeys) = keys %qryVarValues ;
			local (@qryVarUTestKeys) = keys %qvyVarUTests ;

			# If the record has been loaded, try using the loaded record id
			local $nTryRecID = (($E_recIDVar ne '' && $varValues{$E_recIDVar} ne '' && $globalFields{$kg_GetRecVarValues} eq 'true') ? $varValues{$E_recIDVar} : -1) ;

			# If no loaded record id, maybe use an index file to get the record id
			if ($nTryRecID < 0 && $#qryVarValueKeys >= 0 && $#qryVarUTestKeys < 0 && $E_matchEmpty ne 'Yes' && $E_recIDVar ne '' && !defined $qryVarValues{$E_recIDVar} && $E_useIndexFile eq 'Yes')
			{
				# Calculate the index file path
				my $idxPath = $path . &SafeEval (&ExpandShortVarRefs ($E_indexFileExt)) ;
				# Get the record id from the first matching record
				my (@recIDs) = &GetRecIDs ($idxPath) ;
				# Try matching the record id
				$nTryRecID = $recIDs[0] if ($#recIDs >= 0) ;
			}

			# Index the query variables
			local (%qryVarIdx) = () ;
			{
				local $qryVar ;
				foreach $qryVar (@qryVarValueKeys)
				{
					for (local $iii = 0 ; $iii <= $#varList ; $iii++)
					{
						if ($varList[$iii] eq $qryVar)
						{
							$qryVarIdx{$qryVar} = $iii ;
							last ;
						}
					}
				}
			}

			# Skip first row as it contains variable names
			for (local $iii = 1; $iii <= $#recArray; $iii++)
			{
				local $bMatch = 'true' ;
				local $bTriedRecID = 'false' ;

				local $sLine = $recArray[$iii] ;	# Use a temporary variable to remove the newline at the end
				chomp ($sLine) ;						# Remove the line break (Perl 5)
				$sLine =~ s/\r$// ;					# A carriage return character could still be at the end of the line

				if ($nTryRecID >= 0)
				{
					# Assumes the record id is in the first column
					local $nPos = index ($sLine, ",") ;
					if ($nPos > 0)
					{
						# Get the record id from the first column
						local $nRecID = substr ($sLine, 0, $nPos) ;
						$bMatch = 'false' if ($nRecID != $nTryRecID) ;
						$bTriedRecID = 'true' ;
					}
				}

				if ($bTriedRecID ne 'true')
				{
					# Split into an associative array of only query variable values
					local (%recQryVal) = &RecordToValuesList ($sLine, \%qryVarIdx) ;

					# Compare the query values to the record's values
					local $qryVar ;
					foreach $qryVar (@qryVarValueKeys)
					{
						local $qVal = $qryVarValues{$qryVar} ;
						local $rVal = $recQryVal{$qryVar} ;
						if (defined ($qryVarUTests{$qryVar}))
						{
							if (!&SafeEval ($qryVarUTests{$qryVar}))
							{
								$bMatch = 'false' ;
							}
						}
						elsif ($E_matchEmpty eq 'Yes')
						{
							if (defined ($rVal) && $rVal ne '')
							{
								if ((uc $rVal) ne (uc $qVal))
								{
									$bMatch = 'false' ;
								}
							}
						}
						elsif ((uc $rVal) ne (uc $qVal))
						{
							$bMatch = 'false' ;
						}
						last if ($bMatch eq 'false') ;
					}
				}

				# If a match is found, replace the record with the new one
				if ($bMatch eq 'true')
				{
					# 2002-09-04 - RZW: Intermittently, 0s are inserted at the beginning of the data file.
					# Replace the variable list to rule out possible memory overwrite defect
					{
						local $vv = join (',', @varList) ;
						$vv .= "\n" ;
						$recArray[0] = $vv ;
					}
					
					# Replace the record
					{
						local $vv = join (',', @varValues) ;
						$vv .= "\n" ;
						$recArray[$iii] = $vv ;
					}

					$bFound = 'true' ;
				}
				last if ($bFound eq 'true') ;
			}
		}

		if ($bFound eq 'true')
		{
			# Close the file
			close ($fileHandle) ;

			# Reopen the file for truncating
			$fileHandle = $path ;
			if (open ($fileHandle, ">$path"))
			{
				# Write the array to the data file
				print ($fileHandle @recArray) || &DieMsg () ;
			}
		}
		else
		{
			# Seek to the end of the data file
			seek ($fileHandle, 0, 2) || &DieMsg ("Fatal Error",
															 "The script cannot process your survey because ".
															 "it cannot seek to the end of the file (" . &HTMLEncodeText ($path) . "): $! ($?).",
															 "Please contact this site's webmaster.") ;
			# Append the variable values
			$,= ',' ;													# Comma delimited
			print ($fileHandle @varValues) || &DieMsg () ;	# Write the variable value list
			print ($fileHandle "\n") || &DieMsg ();			# Add a newline
		}

		# Close the file
		close ($fileHandle) ;

		# Maybe recreate the index file
		{
			local (@qryVarValueKeys) = keys %qryVarValues ;
			local (@qryVarUTestKeys) = keys %qvyVarUTests ;
			&WriteIndexFile ($path) if ($bFound ne 'true' && $E_useIndexFile eq 'Yes' && $#qryVarValueKeys >= 0 && $#qryVarUTestKeys < 0 && $E_matchEmpty ne 'Yes' && $E_recIDVar ne '' && !defined $qryVarValues{$E_recIDVar}) ;
		}
	}
	else
	{
		&DieMsg ("Fatal Error",
					"The script cannot process your survey because ".
					"it cannot open the data file (" . &HTMLEncodeText ($path) . ") for reading and writing: $! ($?).",
					"Please contact this site's webmaster.") ;
	}

	1 ; # return true
}

# Subroutine byLCAfterComma
#
# Compares the lower-case version of what follows the first comma.

sub byLCAfterComma
{
	my $aComma = index ($a, ",") ;
	my $bComma = index ($b, ",") ;
	if ($aComma >= 0 && $bComma >= 0)
	{
		my $aSep = index ($a, $kIndexFileSeparator) ;
		my $bSep = index ($b, $kIndexFileSeparator) ;
		my $nCmp = 0 ;
		if ($aSep > $aComma && $bSep > $bComma)
		{
			$nCmp = lc (substr ($a, $aComma + 1, $aSep - $aComma - 1)) cmp lc (substr ($b, $bComma + 1, $bSep - $bComma - 1)) ;
		}
		else
		{
			$nCmp = lc (substr ($a, $aComma + 1)) cmp lc (substr ($b, $bComma + 1)) ;
		}
		if ($nCmp == 0)
		{
			my $aID = substr ($a, 0, $aComma) ;
			my $bID = substr ($b, 0, $bComma) ;
			return (-1) if ($aID < $bID) ;
			return (1) if ($aID > $bID) ;
		}
		return ($nCmp) ;
	}
	return (lc ($a) cmp lc ($b)) ;
}

# Subroutine WriteIndexFile
#
# Creates and writes an index file for the data file.

sub WriteIndexFile
{
	local $path = $_[0] ;
	local (@datArray) ;									# Holds the contents of the data file
	local (%qryIdxVarPos) = () ;						# Holds the query variable positions
	local (@qryIdxVar) ;									# Holds the query variable names
	local (@idxArray) ;									# Holds the contents of the index file
	local (@vlst) ;										# Holds the list of variables

	# Load the data file into @datArray
	{
		local $dataFH = $path ;

		# Open the data file for reading
		if (open ($dataFH, "<$path"))
		{
			# Load the data file into an array
			while (defined ($_ = <$dataFH>))			# Read the next record
			{
				push (@datArray, $_) ;					# Add to the array
			}
			# Close the file
			close ($dataFH) ;
		}
		else
		{
			&DieMsg ("Fatal Error",
						"The script cannot process your survey because ".
						"it cannot open the data file (" . &HTMLEncodeText ($path) . ") for reading: $! ($?).",
						"Please contact this site's webmaster.") ;
		}
	}
	if ($#datArray >= 0)
	{
		# Intialize @vlst
		{
			local $sLine = $datArray[0] ;				# Use a temporary variable to remove the newline at the end
			chomp ($sLine) ;								# Remove the line break (Perl 5)
			$sLine =~ s/\r$// ;							# A carriage return character could still be at the end of the line
			@vlst = split (/,/, $sLine) ;
		}
		# Initialize %qryIdxVarPos and @qryIdxVar
		{
			{
				local $qryVar ;
				foreach $qryVar (keys %qryVarValues)
				{
					if ($qryVar ne $E_recIDVar)
					{
						for (local $iii = 0 ; $iii <= $#vlst ; $iii++)
						{
							if ($vlst[$iii] eq $qryVar)
							{
								$qryIdxVarPos{$qryVar} = $iii ;
								last ;
							}
						}
					}
				}
			}
			$qryIdxVarPos{$E_recIDVar} = 0;
			{
				local $lastVarPos = -1 ;
				foreach $qqq (keys %qryIdxVarPos)
				{
					local $nextVarPos = -1 ;
					local $qryVar ;
					foreach $qryVar (keys %qryIdxVarPos)
					{
						if (($lastVarPos < 0 || $qryIdxVarPos{$qryVar} > $lastVarPos) && ($nextVarPos < 0 || $qryIdxVarPos{$qryVar} < $nextVarPos))
						{
							$nextVarPos = $qryIdxVarPos{$qryVar} ;
							$nextQryVar = $qryVar ;
						}
					}
					push (@qryIdxVar, $nextQryVar) ;
					$lastVarPos = $nextVarPos ;
				}
			}
		}
		# Initialize @idxArray
		{
			for (local $iii = 1; $iii <= $#datArray; $iii++)
			{
				local (%datQryVal) = {} ;
				{
					# Use a temporary variable to remove the newline at the end
					local $sLine = $datArray[$iii] ;
					chomp ($sLine) ;					# Remove the line break (Perl 5)
					$sLine =~ s/\r$// ;				# A carriage return character could still be at the end of the line

					# Split into an associative array of only query variable values
					%datQryVal = &RecordToValuesList ($sLine, \%qryIdxVarPos) ;
				}
				{
					local $part1 = '' ;
					local $part2 = '' ;
					for (local $jjj = 0; $jjj <= $#qryIdxVar; $jjj++)
					{
						local $value1 = $datQryVal{$qryIdxVar[$jjj]} ;
						local $value2 = $value1 ;
						{
							$value2 =~ s/"/""/g ;			# Replace double quotes with two
							$_ = $value2 ;
							local $cntComma = tr/,/,/ ;  	# Count the number of commas
							local $cntQuote = tr/"/"/ ;  	# Count the number of double quotes
							$value2 = "\"".$value2."\"" if ($cntComma != 0 || $cntQuote != 0) ; # Enclose the value in double quotes
						}
						$value1 =~ s/|/|-/g ;				# Replace | with |-

						$part1 .= ',' if ($jjj > 0) ;
						$part1 .= $value1 ;
						$part2 .= ',' if ($jjj > 0) ;
						$part2 .= $value2 ;
					}
					# Concatenate using $kIndexFileSeparator which cannot occur in part 1
					push (@idxArray, $part1 . $kIndexFileSeparator . $part2 . "\n") ;
				}
			}
		}
	}
	# Sort the @idxArray
	{
		@idxArray = sort byLCAfterComma @idxArray ;
	}
	# Remove part 1
	{
		for (local $iii = 0; $iii <= $#idxArray; $iii++)
		{
			local $len = length ($idxArray[$iii]) ;
			local $pos = index ($idxArray[$iii], $kIndexFileSeparator, 0) ;
			$idxArray[$iii] = substr ($idxArray[$iii], 0 - $len + $pos + 2) if ($pos >= 0) ;
		}
	}
	# Add the list of variables
	{
		unshift (@idxArray, join (',', @qryIdxVar) . "\n") ;
	}
	# Write the index file
	{
		local $idxPath = $path . &SafeEval (&ExpandShortVarRefs ($E_indexFileExt)) ;
		local $idxFH = $idxPath ;

		# Open the index file for truncating
		if (open ($idxFH, ">$idxPath"))
		{
			my @verInfo = ($kIndexFileVersion, $#idxArray) ;	# Put version information into array
			$,= ',' ;														# Comma delimited
			print ($idxFH @verInfo) || &DieMsg () ;				# Write the version information
			print ($idxFH "\n") || &DieMsg ();						# Add a newline
			if ($#idxArray >= 0)
			{
				# Write the array to the index file
				$,= '' ;															# Not comma delimited
				print ($idxFH @idxArray) || &DieMsg () ;
			}
			# Close the index file
			close ($idxFH) ;
		}
		else
		{
			&DieMsg ("Fatal Error",
						"The script cannot process your survey because ".
						"it cannot open the index file (" . &HTMLEncodeText ($idxPath) . ") for writing: $! ($?).",
						"Please contact this site's webmaster.") ;
		}
	}
}
	
# Subroutine AppendDataFile
#
# Appends the variable values at the end of the data file.

sub AppendDataFile
{
	local ($path) = $_[0] ;
	local ($fileHandle) = $path ;
	
	if	(open ($fileHandle, ">>$path"))						# Open the file for appending
	{
		$,= ',' ;													# Comma delimited
		print ($fileHandle @varValues) || &DieMsg () ;	# Write the variable value list
		print ($fileHandle "\n") || &DieMsg ();			# Add a newline

		close ($fileHandle) ;									# Close and release lock
	}
	else
	{
		&DieMsg ("Fatal Error",
					"The script cannot process your survey because ".
					"it cannot append to the data file (" . &HTMLEncodeText ($path). "): $! ($?). ",
					"Please contact this site's webmaster.") ;
	}
	1; # return true
}

# Subroutine CheckPathExists
#
# Returns "true" if the path parameter points to a file that exists,
# is readable and writeable. Otherwise, returns "false".

sub CheckPathExists
{
	local ($pathExists) = "false" ;
	local ($path) = $_[0] ;

	# Test permissions
	if (-e $path)
	{
		# Path exists
		$pathExists = "true" ;
		if (-d $path)
		{
			# Path is to a directory
			&DieMsg ("Fatal Error",
					   "The script cannot process your survey because ".
						&HTMLEncodeText ($path) . " is not a valid file name.",
						"Please contact this site's webmaster.") ;
		}
		elsif (!-r $path)
		{
			# Path is not readable
			&DieMsg ("Fatal Error",
						"The script cannot process your survey because ".
						"you do not have permission to read " . &HTMLEncodeText ($path) . ".",
					   "Please contact this site's webmaster.") ;
		}
		elsif (!-w $path)
		{
			# Path is write-protected
			&DieMsg ("Fatal Error",
						"The script cannot process your survey because ".
						"you do not have permission to modify " . &HTMLEncodeText ($path) . ".",
						"Please contact this site's webmaster." );
		}
	}
	return $pathExists ;
}

# Subroutine CheckDataFile
#
# Tests the given data file by comparing the first line to the given
# list of variables. If the first line matches the list of variables,
# returns "matched". If the first line is empty, returns "empty". If
# unable to open the file or the first line does not match the list of
# variables, dies.

sub CheckDataFile
{
	local ($path) = $_[0] ;
	local ($vlst) = $_[1] ;
	local ($fileHandle) = $path ;
	local ($result) ;
	
	if (open ($fileHandle, "<$path"))				# Open the data file read-only
	{
		local ($vlstLength) = length ($vlst) ;

		# Read the variable list from the data file
		local ($gotVlst) = <$fileHandle> ;
		chomp ($gotVlst) ;								# Remove the line break (Perl 5)
		$gotVlst =~ s/\r$// ;							# A carriage return character could still be at the end of the line
		local ($gotVlstLength) = length ($gotVlst) ;

		close ($fileHandle) ;

		# Is the list empty?
		if ($gotVlstLength == 1 || $gotVlst eq '')
		{
			$result = "empty" ;
		}
		elsif ($gotVlstLength != $vlstLength || $gotVlst ne $vlst)
		{
			&DieMsg ("Fatal Error",
						"The script cannot process your survey. ".
						"The data file (" . &HTMLEncodeText ($path) . ") ".
						"is either intended for another Web survey or contains ".
						"corrupted or out-of-date data.",
						"Please contact this site's webmaster.") ;
		}
		else
		{
			$result = "matched" ;
		}
	}
	else
	{
		&DieMsg ("Fatal Error",
					"The script cannot process your survey because ".
					"it cannot open the data file (" . &HTMLEncodeText ($path) . ") for reading: $! ($?).",
					"Please contact this site's webmaster.") ;
	}
	return $result ;
}

# Subroutine OpenDataFileReadOnly
#
# Opens the data file. Returns the file handle if successful. If not
# successful, dies.

sub OpenDataFileReadOnly
{
	local ($path) = $_[0] ;
	local ($fileHandle) = $path ;
	
	# Open the data file read-only
	open ($fileHandle, "<$path") || &DieMsg ("Fatal Error",
														  "The script cannot process your survey because ".
														  "it cannot open the data file (" . &HTMLEncodeText ($path) . ") for reading: $! ($?).",
														  "Please contact this site's webmaster.") ;

	return $fileHandle ;
}

# Subroutine ReadDataFileRecord
#
# Reads a line from the open data file. Returns the contents of the
# line without the linefeed character at the end.

sub ReadDataFileRecord
{
	local ($fileHandle) = $_[0] ;		# Get the file handle
	local ($recData) = '' ;				# Record data to be returned

	$recData = <$fileHandle> ;			# Read the next record
	if ($recData ne '')
	{
		chomp ($recData) ;				# Remove the line break (Perl 5)
		$recData =~ s/\r$// ;			# A carriage return character could still be at the end of the line
	}
	return $recData ;						# Return the record
}

# Subroutine ReadTextFile
#
# Reads the entire file and stores it in a string. Returns
# the string. Dies if there is an error.

sub ReadTextFile
{
	local ($path) = $_[0] ;
	local ($fileHandle) = $path ;
	
	# Open the data file read-only
	open ($fileHandle, "<$path") || &DieMsg ("Fatal Error",
														  "The script cannot process your survey because ".
														  "it cannot open the file (" . &HTMLEncodeText ($path) . ") for reading: $! ($?).",
														  "Please contact this site's webmaster.") ;

	# Seek to the end of the file
	seek ($fileHandle, 0, 2) || &DieMsg ("Fatal Error",
													 "The script cannot process your survey because ".
													 "it cannot seek to the end of the file (" . &HTMLEncodeText ($path). "): $! ($?).",
													 "Please contact this site's webmaster.") ;

	# This is the size (in bytes) of the file
	local ($fileSize) = tell ($fileHandle) ;

	# Seek to the beginning of the file
	seek ($fileHandle, 0, 0) || &DieMsg ("Fatal Error",
													 "The script cannot process your survey because ".
													 "it cannot seek to the beginning of the file (" . &HTMLEncodeText ($path) . "): $! ($?).",
													 "Please contact this site's webmaster.") ;

	local ($fileContents) ;
	
	local ($readSize) = read ($fileHandle, $fileContents, $fileSize) ;
#	if ($readSize != $fileSize)
#	{
#		&DieMsg ("Fatal Error",
#					"The script cannot process your survey because ".
#					"it read $readSize of $fileSize bytes from the file (" . &HTMLEncodeText ($path) . ").",
#					"Please contact this site's webmaster.") ;
#	}

	# Close the file
	close ($fileHandle) ;

	return $fileContents ;
}

# Subroutine CopyTextFile
#
# Copies the contents of the first file to the second file. Overwrites
# the second file if it already exists.

sub CopyTextFile
{
	local $pathSrc = $_[0] ;
	local $pathDst = $_[1] ;
	local $fhSrc = $pathSrc ;
	local $fhDst = $pathDst ;

	# Open the text files
	open ($fhSrc, "<$pathSrc") || &DieMsg ("Fatal Error",
														"The script cannot process your survey because ".
														"it cannot open the file (" . &HTMLEncodeText ($pathSrc) . ") for reading: $! ($?).",
														"Please contact this site's webmaster.") ;
	open ($fhDst, ">$pathDst") || &DieMsg ("Fatal Error",
														"The script cannot process your survey because ".
														"it cannot open the file (" . &HTMLEncodeText ($pathDst) . ") for writing: $! ($?).",
														"Please contact this site's webmaster.") ;

	# Copy the source text file
	while (defined ($_ = <$fhSrc>))		# Read the next line
	{
		# Write the line
		print ($fhDst $_) || &DieMsg ("Fatal Error",
												"The script cannot process your survey because ".
												"it cannot write to the file (" . &HTMLEncodeText ($pathDst) . "): $! ($?).",
												"Please contact this site's webmaster.") ;
	}

	# Close the files
	close ($fhSrc) ;
	close ($fhDst) ;
}

# Subroutine AppendTextFile
#
# Appends the array to the text file. Dies if there is an error. The
# first parameter is the path of the text file.

sub AppendTextFile
{
	my (@content) = @_;
	my $path = $content[0] ;
	local $fileHandle = $path ;
	
	if	(open ($fileHandle, ">>$path"))								# Open the file for appending
	{
		for (my $iii = 1 ; $iii <= $#content ; $iii += 2)
		{
			print ($fileHandle "\n") || &DieMsg () if ($iii > 1) ;												# Maybe add a new line
			print ($fileHandle $content[$iii]) || &DieMsg () ;														# Add content
			print ($fileHandle "=" . $content[$iii + 1]) || &DieMsg () if ($iii + 1 <= $#content) ;	# Maybe add more content
		}
		close ($fileHandle) ;											# Close and release lock
	}
	else
	{
		&DieMsg ("Fatal Error",	"The script cannot process your survey because it cannot append to the text file (" . &HTMLEncodeText ($path) . "): $! ($?). ", "Please contact this site's webmaster.") ;
	}
	1; # return true
}

# Subroutine PerformTest1_1of2
#
# Tests the data file to verify that the file has not changed since the
# last time it was modified. Makes a copy of both the data file and the
# backup copy if the two files are different.

sub PerformTest1_1of2
{
	local $pathOrg = $_[0] ;
	local $bakAddExt = &SafeEval (&ExpandShortVarRefs ($E_test1BakAddExt)) ;
	local $pathBak = $pathOrg . $bakAddExt ;

	# Does the backup file exist?
	if (-e $pathBak)
	{
		local $fhOrg = $pathOrg ;
		local $fhBak = $pathBak ;
	
		# Open the data files read-only
		open ($fhOrg, "<$pathOrg") || &DieMsg ("Fatal Error",
															"The script cannot process your survey because ".
															"it cannot open the data file (" . &HTMLEncodeText ($pathOrg) . ") for reading: $! ($?).",
															"Please contact this site's webmaster.") ;
		open ($fhBak, "<$pathBak") || &DieMsg ("Fatal Error",
															"The script cannot process your survey because ".
															"it cannot open the data file (" . &HTMLEncodeText ($pathBak) . ") for reading: $! ($?).",
															"Please contact this site's webmaster.") ;

		# Are the lines different?
		local $bDiff = 0 ;
		while (defined ($_ = <$fhOrg>))		# Read the next line
		{
			local $lineOrg = $_ ;
			if (defined ($_ = <$fhBak>))		# Read the next line
			{
				if ($lineOrg ne $_)				# Are the lines different?
				{
					$bDiff = 1 ;					# The lines are different
					last ;
				}
			}
			else
			{
				$bDiff = 1 ;						# There is no line
				last ;
			}
		}

		$bDiff = 1 if ($bDiff == 0 && defined ($_ = <$fhBak>)) ;

		# Close the data files
		close ($fhOrg) ;
		close ($fhBak) ;

		# Are the files different
		if ($bDiff != 0)
		{
			# Copy the data files
			local $errAddExt = &SafeEval (&ExpandShortVarRefs ($E_test1ErrAddExt)) ;
			local $pathOrgErr = $pathOrg . $errAddExt ;
			local $pathBakErr = $pathBak . $errAddExt ;
			&CopyTextFile ($pathOrg, $pathOrgErr) ;
			&CopyTextFile ($pathBak, $pathBakErr) ;
		}
	}
}

# Subroutine PerformTest1_2of2
#
# Backs up the data file.

sub PerformTest1_2of2
{
	local $pathOrg = $_[0] ;
	local $bakAddExt = &SafeEval (&ExpandShortVarRefs ($E_test1BakAddExt)) ;
	local $pathBak = $pathOrg . $bakAddExt ;
	&CopyTextFile ($pathOrg, $pathBak) ;
}

# Subroutine GetTagAttributeValues
#
# Returns an array containing matches of the given patterns. The first parameter
# is the source string. All of the other parameters are patterns. Each pattern is
# applied to the result of the last pattern. It is assumed that after the first
# pattern is applied, the result in each successive pattern is a single string.

sub GetTagAttributeValues
{
	local (@args) = @_ ;
	local (@matchList) ;
	local (@valueList) ;

	@matchList = ($args[0] =~ m/$args[1]/gi) ;

	for (local ($iii) = 0 ; $iii <= $#matchList ; $iii++)
	{
		local ($value) = $matchList[$iii] ;
		for (local ($jjj) = 2 ; $jjj <= $#args ; $jjj++)
		{
			local (@tempList) = ($value =~ m/$args[$jjj]/gi) ;
			$value = $tempList[0] ;
		}
		push (@valueList, $value) ;
	}
	return (@valueList) ;
}

# Subroutine ReplaceTagAttributeValues
#
# Replaces pattern matches with a string. The first parameter is the source
# string. The next parameters up to but not including the last parameter are
# search patterns. Each search pattern is applied to each of the results of
# the previous search pattern. Can have many results for each search pattern.
# The last search pattern in the parameter list is used with the replacement
# string to make the replacement. Changed strings are then propagated back
# to the original string.
#
# The return value is the possibly modified source string.

sub ReplaceTagAttributeValues
{
	local (@args) = @_ ;

	if ($#args > 2)
	{
		local (@matchList) = ($args[0] =~ m/$args[1]/gi) ;

		for (local ($iii) = 0 ; $iii <= $#matchList ; $iii++)
		{
			local (@rargs) = ();
			for (local ($jjj) = 2; $jjj <= $#args; $jjj++)
			{
				push (@rargs, $args[$jjj]) ;
			}
			local ($repl) = &ReplaceTagAttributeValues ($matchList[$iii], @rargs) ;
			local ($pattern) = quotemeta ($matchList[$iii]) ;
			$args[0] =~ s/$pattern/$repl/gi ;
		}
	}
	else
	{
		$args[0] =~ s/$args[1]/$args[2]/gi ;
	}
	return ($args[0]) ;
}

# Subroutine GetStandardTagAttributeValue
#
# Uses a set of search patterns that work for NAME="" VALUE="" tag attributes
# to get the contents of the VALUE attribute. Returns what is inside the
# double quotes for the VALUE attribute.

sub GetStandardTagAttributeValue
{
	local ($page) = $_[0] ;
	local ($name) = $_[1] ;

	local (@values) = &GetTagAttributeValues ($page, 'NAME\s*=\s*"?' . $name . '"?\s+VALUE\s*=\s*"[^"]*"', 'VALUE\s*=\s*"[^"]*"', '"[^"]*"', '[^"]+') ;

	return ($values[0]) ;
}

# Subroutine ReplaceStandardTagAttributeValue
#
# Uses a set of search patterns to replace the VALUE="" in a NAME="" VALUE=""
# string. Returns the modified source string.

sub ReplaceStandardTagAttributeValue
{
	local ($page) = $_[0] ;
	local ($name) = $_[1] ;
	local ($value) = $_[2] ;

	$page = &ReplaceTagAttributeValues ($page, 'NAME\s*=\s*"?' . $name . '"?\s+VALUE\s*=\s*"[^"]*"', 'VALUE\s*=\s*"[^"]*"', 'VALUE="' . $value . '"') ;

	return ($page) ;
}

# Subroutine InsertFwdVarValuesAndFixups
#
# Replaces a part of the given source string with the contents of %fwdVarValues.
# Returns the modified string source.

sub InsertFwdVarValuesAndFixups
{
	local ($page) = $_[0] ;
	local ($key ) ;
	local ($repl) = '' ;

	{
		local ($fvv) = join (',', @fwdVarValues);
		$page = &ReplaceStandardTagAttributeValue ($page, 'E_varFwdVal', $fvv) ;
	}

	foreach $key (keys %fwdVarFixups)
	{
		if ($repl ne '')
		{
			$repl .= "\n" ;
		}
		$repl .= "<input type=\"HIDDEN\" name=\"X_$key\" value=\"$fwdVarFixups{$key}\">" ;
	}
	
	$page =~ s/<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?E_varValues"?\s+VALUE\s*=\s*[^>]*>/$repl/gi ;
	return $page ;
}

# Subroutine InsertGlobalFields
#
# Replaces a part of the given source string with the contents of %globalFields.
# Returns the modified source string.

sub InsertGlobalFields
{
	local ($text) = $_[0] ;

	if (%globalFields)
	{
		local ($key ) ;
		local ($repl) = "\n\n<!-- Global Fields (Please do not modify) -->" ;

		foreach $key (keys %globalFields)
		{
			if ($repl ne '')
			{
				$repl .= "\n" ;
			}
			$repl .= "<input type=\"hidden\" name=\"G_$key\" value=\"$globalFields{$key}\">" ;
		}

		# Using the same tag as InsertQryVarValues
		# Change this when ready to go to the next version (version 5)
		$text =~ s/<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?E_qryValues"?\s+VALUE\s*=\s*[^>]*>/$&$repl/gi ;
	}
	return $text ;
}

# Subroutine InsertScriptExprResultFields
#
# Replaces a part of the given source string with the contents of
# %scriptExprResults. Returns the modified source string.

sub InsertScriptExprResultFields
{
	local $text = $_[0] ;

	if (%scriptExprResults)
	{
		local $key ;
		local $repl = "\n\n<!-- Script Expression Result Fields (Please do not modify) -->" ;
		foreach $key (keys %scriptExprResults)
		{
			if ($repl ne '')
			{
				$repl .= "\n" ;
			}
			$repl .= "<input type=\"hidden\" name=\"J_$key\" value=\"$scriptExprResults{$key}\">" ;
		}

		# Using the same tag as InsertQryVarValues
		# Change this when ready to go to the next version (version 5)
		$text =~ s/<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?E_qryValues"?\s+VALUE\s*=\s*[^>]*>/$&$repl/gi ;
	}
	return $text ;
}

# Subroutine InsertCheckReloadFileNameFields
#
# Replaces a part of the given source string with fields to be used to
# check the E_reloadFileName environment variable. Works around Safari
# browser defect #8613. A description of the defect can be found at
# http://bugzilla.opendarwin.org/show_bug.cgi?id=8613

sub InsertCheckReloadFileNameFields
{
	local $text = $_[0] ;
	local $reloadFileName = &GetStandardTagAttributeValue ($text, 'E_reloadFileName') ;
	local $repl = "\n\n<!-- Check E_reloadFileName Fields (Please do not modify) -->" ;
	$repl .= "\n<input type=\"hidden\" name=\"E_checkReloadFileName\" value=\"Yes\">" ;
	$repl .= "\n<input type=\"hidden\" name=\"E_rFN_" . $reloadFileName . "\" value=\"" . $reloadFileName . "\">" ;

	# Using the same tag as InsertQryVarValues
	# Change this when ready to go to the next version (version 5)
	$text =~ s/<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?E_qryValues"?\s+VALUE\s*=\s*[^>]*>/$&$repl/gi ;
	return $text ;
}

# Subroutine InsertQryVarValues
#
# Replaces a part of the given source string with the contents of %qryVarValues.
# Returns the modified source string.

sub InsertQryVarValues
{
	local ($text) = $_[0] ;
	local ($key ) ;
	local ($repl) = '' ;

	foreach $key (keys %qryVarValues)
	{
		if ($repl ne '')
		{
			$repl .= "\n" ;
		}
		local $value = &TagEncodeText ($qryVarValues{$key}) ;
		$value =~ s/\\/\\\\/g ;						# Replace all occurrences of \ with \\
		$value =~ s/'/\\'/g ;						# Replace all occurrences of ' with \'
		$repl .= "<input type=\"HIDDEN\" name=\"Q_$key\" value=\"'$value'\">" ;
	}
	
	$text =~ s/<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?E_qryValues"?\s+VALUE\s*=\s*[^>]*>/$repl/gi ;
	return $text ;
}

# Subroutine InsertWarnings
#
# If there are any warning messages in %rulWrns, replaces a part of the given source string
# with the contents of %rulWrns. Also replaces another part of the given source string with
# a summary list of all of the warnings. Returns the modified source string.

sub InsertWarnings
{
	local $text = $_[0] ;
	local $key ;
	local $summary = '' ;
	local $wrnCnt = 0 ;
	local %wrns = %rulWrns;

	foreach $key (keys %wrns)
	{
		local ($pattern) = '<A\s+NAME\s*=\s*"?' . $key . '["\s>][^<]*</A>' ;
		local (@anchorList) = ($text =~ m|$pattern|gi) ;

		for (local ($iii) = 0; $iii < $#anchorList + 1; $iii++)
		{
			local ($anchor) = $anchorList[$iii] ;
			local ($repl) = "</a>$wrns{$key}<a href=\"#WRNS\">$E_backToWarningSummary</a><br>\n" ;

			$anchor =~ s|</A>|$repl|gi ;
			$text =~ s/$anchorList[$iii]/$anchor/i ;
		}
		if ($summary eq '')
		{
			$summary .= "<h3><a name=\"WRNS\">$E_warningSummaryHeading</a></h3>\n<p>\n" ;
		}
		$wrnCnt += 1 ;

		if ($#anchorList < 0)
		{
			$summary .= "$wrns{$key}\n" ;
		}
		else
		{
			$summary .= "<a href=\"#$key\">$wrns{$key}</a>\n" ;
		}
	}

	if ($summary ne '')
	{
		if (uc $E_incWarningSubmit eq 'YES')
		{
			$summary .= "<p>$E_warningSubmitMessage\n".
							"<input type=\"Submit\" name=\"E_nextIgnoreWarnings\" value=\"$E_warningSubmitValue\">\n" ;
		}
		$summary .= "<hr>" ;
		$text =~ s/<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?E_warningSummary"?\s+VALUE\s*=\s*[^>]*>/$summary/gi ;
	}
	return $text ;
}

# Subroutine InsertErrors
#
# If there are any error messages in %rulErrs, replaces a part of the given source string
# with the contents of %rulErrs. Also replaces another part of the given source string with
# a summary list of all of the errors. Returns the modified source string.

sub InsertErrors
{
	local $text = $_[0] ;
	local $key ;
	local $summary = '' ;
	local $errCnt = 0 ;
	local %errs = (%rulErrs, %sysErrs) ;

	foreach $key (keys %errs)
	{
		local $pattern = '<A\s+NAME\s*=\s*"?' . $key . '["\s>][^<]*</A>' ;
		local (@anchorList) = ($text =~ m|$pattern|gi) ;

		for (local $iii = 0; $iii < $#anchorList + 1; $iii++)
		{
			local $anchor = $anchorList[$iii] ;
			local $repl = "</a>$errs{$key}<a href=\"#ERRS\">$E_backToErrorSummary</a><br>\n" ;

			$anchor =~ s|</A>|$repl|gi ;
			$text =~ s/$anchorList[$iii]/$anchor/i ;
		}
		if ($summary eq '')
		{
			$summary .= "<h3><a name=\"ERRS\">$E_errorSummaryHeading</a></h3>\n<p>\n" ;
		}
		$errCnt += 1 ;

		if ($#anchorList < 0)
		{
			$summary .= "$errs{$key}\n" ;
		}
		else
		{
			$summary .= "<a href=\"#$key\">$errs{$key}</a>\n" ;
		}
	}

	if ($summary ne '')
	{
		$summary .= "<hr>" ;
		$text =~ s/<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?E_errorSummary"?\s+VALUE\s*=\s*[^>]*>/$summary/gi ;
	}
	return $text ;
}

# Subroutine InsertInsVarValues
#
# Replaces values in the source string using %insVarValues for instructions
# with values in %ansVarValues. Returns the modified source string.

sub InsertInsVarValues
{
	local ($text) = $_[0] ;
	local ($key) ;

	foreach $key (keys %insVarValues)
	{
		local (@insType) = split (/,/, $insVarValues{$key}, 2) ;
		if (defined ($ansVarValues{$key}))
		{
			if ($insType[0] eq "1")
			{
				$text = &InsertInputTypeTextVarValue ($text, $key, $ansVarValues{$key}) ;
			}
			elsif ($insType[0] eq "2")
			{
				$text = &InsertTextAreaVarValue ($text, $key, $ansVarValues{$key}) ;
			}
			elsif ($insType[0] eq "3")
			{
				$text = &InsertInputTypeRadioVarValue ($text, $key, $ansVarValues{$key}) ;
			}
			elsif ($insType[0] eq "4")
			{
				$text = &InsertInputTypeCheckboxVarValue ($text, $key, $ansVarValues{$key}) ;
			}
			elsif ($insType[0] eq "5")
			{
				$text = &InsertSelectVarValue ($text, $key, $ansVarValues{$key}) ;
			}
			elsif ($insType[0] eq "6")
			{
				$text = &InsertSelectMultipleVarValue ($text, $key, $ansVarValues{$key}) ;
			}
			elsif ($insType[0] eq "7")
			{
				$text = &InsertStaticTextVarValue ($text, $key, $ansVarValues{$key}) ;
			}
			elsif ($insType[0] eq "8")
			{
				$text = &InsertNonFormStaticTextVarValue ($text, $key, $ansVarValues{$key}) ;
			}
			elsif ($insType[0] eq "10")
			{
				$text = &InsertNonFormStaticTextLookupValue ($text, $key, $ansVarValues{$key}, $insVarValues{$key}) ;
			}
			elsif ($insType[0] eq "11")
			{
				$text = &InsertInputTypeHiddenVarValue ($text, $key, $ansVarValues{$key}) ;
			}
			elsif ($insType[0] eq "12")
			{
				$text = &InsertInputTypeTextToHiddenVarValue ($text, $key, $ansVarValues{$key}) ;
			}
			elsif ($insType[0] eq "13")
			{
				$text = &InsertInputTypePasswordVarValue ($text, $key, $ansVarValues{$key}) ;
			}
		}
		elsif (defined ($fwdVarValues{$key}))
		{
			if ($insType[0] eq "8")
			{
				$text = &InsertNonFormStaticTextVarValue ($text, $key, $fwdVarValues{$key}) ;
			}
			elsif ($insType[0] eq "10")
			{
				$text = &InsertNonFormStaticTextLookupValue ($text, $key, $fwdVarValues{$key}, $insVarValues{$key}) ;
			}
			elsif ($insType[0] eq "11")
			{
				$text = &InsertInputTypeHiddenVarValue ($text, $key, $fwdVarValues{$key}) ;
			}
			elsif ($insType[0] eq "12")
			{
				$text = &InsertInputTypeTextToHiddenVarValue ($text, $key, $fwdVarValues{$key}) ;
			}
		}
		elsif (defined ($evlVarValues{$key}))
		{
			if ($insType[0] eq "8")
			{
				$text = &InsertNonFormStaticTextVarValue ($text, $key, $evlVarValues{$key}) ;
			}
			elsif ($insType[0] eq "10")
			{
				$text = &InsertNonFormStaticTextLookupValue ($text, $key, $evlVarValues{$key}, $insVarValues{$key}) ;
			}
			elsif ($insType[0] eq "11")
			{
				$text = &InsertInputTypeHiddenVarValue ($text, $key, $evlVarValues{$key}) ;
			}
			elsif ($insType[0] eq "12")
			{
				$text = &InsertInputTypeTextToHiddenVarValue ($text, $key, $evlVarValues{$key}) ;
			}
		}

		if ($E_useMulRec eq 'Yes' && defined ($mulRec{$key}))
		{
			if ($insType[0] eq "9")
			{
				local (@insValLst) = split (/,/, $insVarValues{$key}) ;
				local (@mulValLst) = split (/\|/, $mulRec{$key}) ;

				for (local ($valNum) = 1 ; $valNum <= $#mulValLst + 1 ; $valNum++)
				{
					local ($varValue) = $mulValLst[$valNum - 1] ;
					local ($insCmd) = 0 ;

					if ($#insValLst > 1)
					{
						local (%rec) = ();
						foreach $kkk (keys %mulRec)
						{
							local (@recValLst) = split (/\|/, $mulRec{$kkk}) ;
							$rec{$kkk} = $recValLst[$valNum - 1] ;
						}
						$insCmd = &SafeEval (&TagDecodeText ($insValLst[2])) ;
					}
					$text = &InsertMulRecStaticTextVarValue ($text, $key, $varValue, $valNum, $insCmd) ;
				}
			}
		}
	}

	return $text;
}

# Subroutine InsertInputTypeTextVarValue
#
# Replaces values in <INPUT TYPE=TEXT...> fields in the source string with the
# given value. Returns the modified source string.

sub InsertInputTypeTextVarValue
{
	local ($text) = $_[0] ;
	local ($varName) = $_[1] ;
	local ($varValue) = $_[2] ;

	# Value cannot contain the double quotation mark
	# Replace all occurrences of the double quotation mark with the single quotation mark
	$varValue =~ s/"/'/g ;
	
	local ($pattern) = '<INPUT\s+TYPE\s*=\s*"?TEXT"?\s+NAME\s*=\s*"V_' . $varName . '"[^>]*>' ;
	local (@matchList) = ($text =~ m/$pattern/gi) ;

	for (local ($iii) = 0; $iii < $#matchList + 1; $iii++)
	{
		local ($repl) ;
		$pattern = 'VALUE\s*=\s*"[^"]*"' ;
		local (@oldVal) = ($matchList[$iii] =~ m/$pattern/gi) ;
		if ($#oldVal < 0 || $oldVal[0] eq '')
		{
			$pattern = '>' ;
			$repl = " value=\"$varValue\">" ;
		}
		else
		{
			$pattern = $oldVal[0] ;
			$repl = "value=\"$varValue\"" ;
		}
		local ($newTag) = $matchList[$iii] ;
		$newTag =~ s/$pattern/$repl/i ;
		$pattern = quotemeta ($matchList[$iii]) ;
		$text =~ s/$pattern/$newTag/i ;
	}

	return $text ;
}

# Subroutine InsertTextAreaVarValue
#
# Replaces values in <TEXTAREA...></TEXTAREA> fields in the source string with
# the given value. Returns the modified source string.

sub InsertTextAreaVarValue
{
	local ($text) = $_[0] ;
	local ($varName) = $_[1] ;
	local ($varValue) = $_[2] ;

	local ($pattern) = '<TEXTAREA\s+NAME\s*=\s*"V_' . $varName . '"[^>]*>.*?</TEXTAREA>' ;
	local (@matchList) = ($text =~ m/$pattern/gi) ;

	for (local ($iii) = 0; $iii < $#matchList + 1; $iii++)
	{
		$pattern = '>.*<' ;
		local (@oldVal) = ($matchList[$iii] =~ m/$pattern/gi) ;

		if ($#oldVal >= 0 && $oldVal[0] ne '')
		{
			$pattern = $oldVal[0] ;
			local ($repl) = ">$varValue<" ;

			local ($newTag) = $matchList[$iii] ;
			$newTag =~ s/$pattern/$repl/i ;
			$pattern = quotemeta ($matchList[$iii]) ;
			$text =~ s/$pattern/$newTag/i ;
		}
	}

	return $text ;
}

# Subroutine InsertInputTypeRadioVarValue
#
# Replaces values in <INPUT TYPE=RADIO...> fields in the source string with the given
# value. Returns the modified source string.

sub InsertInputTypeRadioVarValue
{
	local ($text) = $_[0] ;
	local ($varName) = $_[1] ;
	local ($varValue) = $_[2] ;

	if ($varValue ne '')
	{
		local ($pattern) = '<INPUT\s+TYPE\s*=\s*"?RADIO"?\s+NAME\s*=\s*"V_' . $varName . '"[^>]*>' ;
		local (@matchList) = ($text =~ m/$pattern/gi) ;

		for (local ($iii) = 0; $iii < $#matchList + 1; $iii++)
		{
			local ($newTag) = $matchList[$iii] ;
			local ($repl) = '';
			$pattern = '\s*CHECKED' ;

			# Remove all occurrences of CHECKED
			$newTag =~ s/$pattern/$repl/gi ;

			$pattern = 'VALUE\s*=\s*"' . $varValue. '"' ;
			local (@fndVal) = ($newTag =~ m/$pattern/gi) ;
			if ($#fndVal >= 0)
			{
				$repl = "$fndVal[0] checked";
				$newTag =~ s/$pattern/$repl/i ;
			}
			$pattern = quotemeta ($matchList[$iii]) ;
			$text =~ s/$pattern/$newTag/i ;
		}
	}

	return $text ;
}

# Subroutine InsertInputTypeCheckboxVarValue
#
# Replaces values in <INPUT TYPE=CHECKBOX...> fields in the source string with the given
# value. Returns the modified source string.

sub InsertInputTypeCheckboxVarValue
{
	local ($text) = $_[0] ;
	local ($varName) = $_[1] ;
	local ($varValue) = $_[2] ;

	if ($varValue ne '')
	{
		local ($pattern) = '<INPUT\s+TYPE\s*=\s*"?CHECKBOX"?\s+NAME\s*=\s*"V_' . $varName . '"[^>]*>' ;
		local (@matchList) = ($text =~ m/$pattern/gi) ;

		for (local ($iii) = 0; $iii < $#matchList + 1; $iii++)
		{
			local ($newTag) = $matchList[$iii] ;
			$pattern = '\s*CHECKED' ;

			# Remove all occurrences of CHECKED
			$newTag =~ s/$pattern//gi ;

			if ($varValue eq "1")
			{
				$pattern = '>' ;
				local ($repl) = ' checked>';
				$newTag =~ s/$pattern/$repl/i ;
			}
			$pattern = quotemeta ($matchList[$iii]) ;
			$text =~ s/$pattern/$newTag/i ;
		}
	}

	return $text ;
}

# Subroutine InsertSelectVarValue
#
# Replaces values in <SELECT...></SELECT> fields in the source string with the given
# value. Returns the modified source string.

sub InsertSelectVarValue
{
	local ($text) = $_[0] ;
	local ($varName) = $_[1] ;
	local ($varValue) = $_[2] ;

	if ($varValue ne '')
	{
		local ($pattern) = '<SELECT\s+NAME\s*=\s*"V_' . $varName . '".*?</SELECT>' ;
		local (@matchList) = ($text =~ m/$pattern/sgi) ;

		for (local ($iii) = 0; $iii < $#matchList + 1; $iii++)
		{
			local ($newTag) = $matchList[$iii] ;
			$pattern = '\s*SELECTED' ;

			# Remove all occurrences of SELECTED
			$newTag =~ s/$pattern//gi ;

			# Find matching option
			$pattern = '<OPTION\s+VALUE\s*=\s*"' . $varValue . '"[^>]*>' ;
			local (@option) = ($newTag =~ m/$pattern/gi) ;

			if ($#option >= 0)
			{
				$pattern = '>' ;
				local ($repl) = ' selected>';
				local ($newOption) = $option[0] ;
				$newOption =~ s/$pattern/$repl/i ;
				$newTag =~ s/$option[0]/$newOption/i ;
			}
			$pattern = quotemeta ($matchList[$iii]) ;
			$text =~ s/$pattern/$newTag/i ;
		}
	}

	return $text ;
}

# Subroutine InsertSelectMultipleVarValue
#
# Replaces values in <SELECT ... MULTIPLE></SELECT> fields in the source string with
# the given value. Returns the modified source string.

sub InsertSelectMultipleVarValue
{
	local ($text) = $_[0] ;
	local ($varName) = $_[1] ;
	local ($varValue) = $_[2] ;

	local ($pattern) = '<OPTION\s+VALUE\s*=\s*"V_' . $varName . ',[^>]*>' ;
	local (@matchList) = ($text =~ m/$pattern/gi) ;

	for (local ($iii) = 0; $iii < $#matchList + 1; $iii++)
	{
		local ($newTag) = $matchList[$iii] ;
		local ($repl) = '';
		$pattern = '\s*SELECTED' ;

		# Remove all occurrences of SELECTED
		$newTag =~ s/$pattern/$repl/gi ;

		if ($varValue eq "1")
		{
			$pattern = '>' ;
			local ($repl) = ' selected>';
			$newTag =~ s/$pattern/$repl/i ;
		}
		$pattern = quotemeta ($matchList[$iii]) ;
		$text =~ s/$pattern/$newTag/i ;
	}

	return $text ;
}

# Subroutine InsertStaticTextVarValue
#
# Replaces values in <INPUT TYPE=TEXT...> fields in the source string with the
# given value. Returns the modified source string.

sub InsertStaticTextVarValue
{
	local ($text) = $_[0] ;
	local ($varName) = $_[1] ;
	local ($varValue) = $_[2] ;

	# Value cannot contain the double quotation mark
	# Replace all occurrences of the double quotation mark with the single quotation mark
	$varValue =~ s/"/'/g ;
	
	local ($pattern) = '<INPUT\s+TYPE\s*=\s*"?TEXT"?\s+NAME\s*=\s*"V_' . $varName . '"[^>]*>' ;
	local (@matchList) = ($text =~ m/$pattern/gi) ;

	for (local ($iii) = 0; $iii < $#matchList + 1; $iii++)
	{
		local ($newTag) = '<input type="HIDDEN" name="V_' . $varName . '" value="' . $varValue . '">' . $varValue ;
		$pattern = quotemeta ($matchList[$iii]) ;
		$text =~ s/$pattern/$newTag/i ;
	}

	return $text ;
}

# Subroutine InsertNonFormStaticTextVarValue
#
# Replaces the entire <INPUT TYPE="HIDDEN" NAME="I_..." VALUE="8"> tags in
# the source string with the given value. Returns the modified source string.

sub InsertNonFormStaticTextVarValue
{
	local ($text) = $_[0] ;
	local ($varName) = $_[1] ;
	local ($varValue) = $_[2] ;

	# Value cannot contain the double quotation mark
	# Replace all occurrences of the double quotation mark with the single quotation mark
	$varValue =~ s/"/'/g ;
	
	local ($pattern) = '<INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"I_' . $varName . '"\s+VALUE="?8"?[^>]*>' ;
	local (@matchList) = ($text =~ m/$pattern/gi) ;

	for (local ($iii) = 0; $iii < $#matchList + 1; $iii++)
	{
		local ($newTag) = $varValue ;
		$pattern = quotemeta ($matchList[$iii]) ;
		$text =~ s/$pattern/$newTag/i ;
	}

	return $text ;
}

# Subroutine InsertMulRecStaticTextVarValue
#
# Replaces the entire <INPUT TYPE="HIDDEN" NAME="I_..." VALUE="9,x"> tags in
# the source string with the given value. Returns the modified source string.

sub InsertMulRecStaticTextVarValue
{
	local ($text) = $_[0] ;
	local ($varName) = $_[1] ;
	local ($varValue) = $_[2] ;
	local ($valNum) = $_[3] ;
	local ($insCmd) = $_[4] ;

	# Value cannot contain the double quotation mark
	# Replace all occurrences of the double quotation mark with the single quotation mark
	$varValue =~ s/"/'/g ;
	
	local ($pattern) = '<INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"I_' . $varName . '"\s+VALUE="9,' . $valNum . '[,"][^>]*>' ;
	local (@matchList) = ($text =~ m/$pattern/gi) ;

	for (local ($iii) = 0; $iii < $#matchList + 1; $iii++)
	{
		local ($newTag) = $varValue ;
		$pattern = quotemeta ($matchList[$iii]) ;
		$text =~ s/$pattern/$newTag/i ;
	}

	# Remove comment tags
	local ($pattern) = '<!-- %%' . $valNum . '%%' ;
	local (@matchList) = ($text =~ m/$pattern/gi) ;

	for (local ($iii) = 0; $iii < $#matchList + 1; $iii++)
	{
		$pattern = quotemeta ($matchList[$iii]) ;
		$text =~ s/$pattern//i ;
	}

	# Remove comment tags
	local ($pattern) = '%%' . $valNum . '%% -->' ;
	local (@matchList) = ($text =~ m/$pattern/gi) ;

	for (local ($iii) = 0; $iii < $#matchList + 1; $iii++)
	{
		$pattern = quotemeta ($matchList[$iii]) ;
		$text =~ s/$pattern//i ;
	}

	if ($insCmd == 1)
	{
		# Remove place holders
		local ($pattern) = '##' . $valNum . '#' ;
		local (@matchList) = ($text =~ m/$pattern/gi) ;

		for (local ($iii) = 0; $iii < $#matchList + 1; $iii++)
		{
			$pattern = quotemeta ($matchList[$iii]) ;
			$text =~ s/$pattern//i ;
		}

		# Remove place holders
		local ($pattern) = '#' . $valNum . '##' ;
		local (@matchList) = ($text =~ m/$pattern/gi) ;

		for (local ($iii) = 0; $iii < $#matchList + 1; $iii++)
		{
			$pattern = quotemeta ($matchList[$iii]) ;
			$text =~ s/$pattern//i ;
		}
	}
	elsif ($insCmd == 2)
	{
		# Remove place holders and everything in between
		local ($pattern) = '##' . $valNum . '#[^#]*#' . $valNum . '##' ;
		local (@matchList) = ($text =~ m/$pattern/gi) ;

		for (local ($iii) = 0; $iii < $#matchList + 1; $iii++)
		{
			$pattern = quotemeta ($matchList[$iii]) ;
			$text =~ s/$pattern//i ;
		}
	}
	
	return $text ;
}

# Subroutine InsertNonFormStaticTextLookupValue
#
# Replaces the entire <INPUT TYPE="HIDDEN" NAME="I_..." VALUE="10,x"> tags in
# the source string with the given value. Returns the modified source string.

sub InsertNonFormStaticTextLookupValue
{
	local $text = $_[0] ;
	local $varName = $_[1] ;
	local $varValue = $_[2] ;
	local $insCmdString = $_[3] ;
	local (@insCmdList) = split (/,/, $insCmdString) ;
	local $insType = shift @insCmdList ;
	local $valueListSize = shift @insCmdList ;
	local (%valueList) = () ;

	# Get the lookup expressions
	{
		for (local $iii = 0; $iii < $valueListSize; $iii++)
		{
			local $value = shift @insCmdList ;
			local $expr = shift @insCmdList ;
			$valueList{$value} = $expr ;
		}
	}

	# Value cannot contain the double quotation mark
	# Replace all occurrences of the double quotation mark with the single quotation mark
	$varValue =~ s/"/'/g ;

	# Is there an override value?
	if (defined ($valueList{$varValue}))
	{
		# Assign the override value
		local $expr = $valueList{$varValue} ;
		$varValue = &SafeEval ($expr) ;
		if ($@)
		{
			&DieMsg ("Fatal Error", "Error in expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
		}
	}

	local ($pattern) = '<INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"I_' . $varName . '"\s+VALUE="10,[^>]*>' ;
	local (@matchList) = ($text =~ m/$pattern/gi) ;

	for (local ($iii) = 0; $iii < $#matchList + 1; $iii++)
	{
		local ($newTag) = $varValue ;
		$pattern = quotemeta ($matchList[$iii]) ;
		$text =~ s/$pattern/$newTag/i ;
	}

	return $text ;
}

# Subroutine InsertInputTypeHiddenVarValue
#
# Replaces values in <INPUT TYPE=HIDDEN...> fields in the source string with the
# given value. Returns the modified source string.

sub InsertInputTypeHiddenVarValue
{
	local $text = $_[0] ;
	local $varName = $_[1] ;
	local $varValue = $_[2] ;

	# Value cannot contain the double quotation mark
	# Replace all occurrences of the double quotation mark with the single quotation mark
	$varValue =~ s/"/'/g ;
	
	local $pattern = '<INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"V_' . $varName . '"[^>]*>' ;
	local (@matchList) = ($text =~ m/$pattern/gi) ;

	for (local $iii = 0; $iii < $#matchList + 1; $iii++)
	{
		local $repl ;
		$pattern = 'VALUE\s*=\s*"[^"]*"' ;
		local (@oldVal) = ($matchList[$iii] =~ m/$pattern/gi) ;
		if ($#oldVal < 0 || $oldVal[0] eq '')
		{
			$pattern = '>' ;
			$repl = " value=\"$varValue\">" ;
		}
		else
		{
			$pattern = $oldVal[0] ;
			$repl = "value=\"$varValue\"" ;
		}
		local $newTag = $matchList[$iii] ;
		$newTag =~ s/$pattern/$repl/i ;
		$pattern = quotemeta ($matchList[$iii]) ;
		$text =~ s/$pattern/$newTag/i ;
	}

	return $text ;
}

# Subroutine InsertInputTypeTextToHiddenVarValue
#
# Replaces values in <INPUT TYPE=TEXT...> fields in the source string with the
# given value. Rewrites the entire tag, converting the type to HIDDEN.
# Returns the modified source string.

sub InsertInputTypeTextToHiddenVarValue
{
	local $text = $_[0] ;
	local $varName = $_[1] ;
	local $varValue = $_[2] ;

	# Value cannot contain the double quotation mark
	# Replace all occurrences of the double quotation mark with the single quotation mark
	$varValue =~ s/"/'/g ;
	
	local $pattern = '<INPUT\s+TYPE\s*=\s*"?TEXT"?\s+NAME\s*=\s*"V_' . $varName . '"[^>]*>' ;
	local (@matchList) = ($text =~ m/$pattern/gi) ;

	for (local $iii = 0; $iii < $#matchList + 1; $iii++)
	{
		local $newTag = '<input type="HIDDEN" name="V_' . $varName . '" value="' . $varValue . '">' ;
		$pattern = quotemeta ($matchList[$iii]) ;
		$text =~ s/$pattern/$newTag/i ;
	}

	return $text ;
}

# Subroutine InsertInputTypePasswordVarValue
#
# Replaces values in <INPUT TYPE=PASSWORD...> fields in the source string with the
# given value. Returns the modified source string.

sub InsertInputTypePasswordVarValue
{
	local ($text) = $_[0] ;
	local ($varName) = $_[1] ;
	local ($varValue) = $_[2] ;

	# Value cannot contain the double quotation mark
	# Replace all occurrences of the double quotation mark with the single quotation mark
	$varValue =~ s/"/'/g ;
	
	local ($pattern) = '<INPUT\s+TYPE\s*=\s*"?PASSWORD"?\s+NAME\s*=\s*"V_' . $varName . '"[^>]*>' ;
	local (@matchList) = ($text =~ m/$pattern/gi) ;

	for (local ($iii) = 0; $iii < $#matchList + 1; $iii++)
	{
		local ($repl) ;
		$pattern = 'VALUE\s*=\s*"[^"]*"' ;
		local (@oldVal) = ($matchList[$iii] =~ m/$pattern/gi) ;
		if ($#oldVal < 0 || $oldVal[0] eq '')
		{
			$pattern = '>' ;
			$repl = " value=\"$varValue\">" ;
		}
		else
		{
			$pattern = $oldVal[0] ;
			$repl = "value=\"$varValue\"" ;
		}
		local ($newTag) = $matchList[$iii] ;
		$newTag =~ s/$pattern/$repl/i ;
		$pattern = quotemeta ($matchList[$iii]) ;
		$text =~ s/$pattern/$newTag/i ;
	}

	return $text ;
}

# Subroutine UpdateBackFileName
#
# Replaces the value in the <INPUT TYPE="HIDDEN" NAME="E_backFileName"...> tag with
# the contents of $E_backFileName. Returns the modified source string.

sub UpdateBackFileName
{
	local ($page) = $_[0] ;
	local ($pathList) = '';

	if ($#E_backFileName >= 0)
	{
		$pathList = join ('|', @E_backFileName) ;
	}
	$page = &ReplaceStandardTagAttributeValue ($page, 'E_backFileName', $pathList) ;

	return $page ;
}

# Subroutine InsertBackButton
#
# Replaces the entire <INPUT TYPE="HIDDEN" NAME="E_backButtonPlaceHolder"...> tag
# with a tag for the back button. Returns the modified source string.

sub InsertBackButton
{
	local ($page) = $_[0] ;

	# Are there any pages to go back to?
	if ($#E_backFileName >= 0)
	{
		# Replace the place holder with a back submit button
		$page = &ReplaceTagAttributeValues ($page, '<INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?E_backButtonPlaceHolder"?[^>]*>', '<INPUT TYPE="SUBMIT" NAME="E_backButton" VALUE="' . $E_backSubmitValue . '">') ;
	}
	return $page ;
}

# Subroutine InsertBookmarkButton
#
# Replaces the entire <input type="hidden" name="E_bookmarkButtonPlaceHolder"...> tag
# with a tag for the bookmark button. Returns the modified source string.

sub InsertBookmarkButton
{
	local $page = $_[0] ;
	if ($E_bookmarkSubmitValue ne '' && $E_recCntVar ne '' && ($fwdVarValues{$E_recCntVar} =~ m/^\d+$E_decimalPoint\d+$/) && $globalFields{$kg_GetRecVarValues} eq 'true')
	{
		local $reloadFileField = &GetStandardTagAttributeValue ($page, 'E_reloadFileName') ;
		local $expr = &TagDecodeText (&GetStandardTagAttributeValue ($page, 'E_nextFileName')) ;
		local $nextFileField = &SafeEval (&ExpandShortVarRefs ($expr)) ;
		if (($reloadFileField =~ m/^E_fileName_\d+$/) && ($nextFileField =~ m/^E_fileName_\d+$/))
		{
			local ($bookmarkPageNum) = ($fwdVarValues{$E_recCntVar} =~ m/^\d+$E_decimalPoint(\d+)$/) ;
			local ($reloadPageNum) = ($reloadFileField =~ m/^E_fileName_(\d+)$/) ;
			local ($nextPageNum) = ($nextFileField =~ m/^E_fileName_(\d+)$/) ;
			if ($bookmarkPageNum != $reloadPageNum && $bookmarkPageNum != $nextPageNum)
			{
				local $bookmarkFileField = &GetStandardTagAttributeValue ($page, 'E_fileName_' . $bookmarkPageNum) ;
				$bookmarkFileField = $conf_data{'E_fileName_' . $bookmarkPageNum} if (defined ($conf_data{'E_fileName_' . $bookmarkPageNum})) ;
				if (defined ($bookmarkFileField) && $bookmarkFileField ne '')
				{
					# Replace the place holder with a bookmark submit button
					$page = &ReplaceTagAttributeValues ($page, '<input\s+type\s*=\s*"?hidden"?\s+name\s*=\s*"?E_bookmarkButtonPlaceHolder"?[^>]*>', '<input type="submit" name="E_bookmarkButton" value="' . $E_bookmarkSubmitValue . '"><input type="hidden" name="E_resetBookmark" value="Yes">') ;
				}
			}
		}
	}
	return $page ;
}

# Subroutine RemoveExistingQueryFields
#
# Removes all occurrences of query variables from the source string. Returns
# the modified source string.

sub RemoveExistingQueryFields
{
	local ($page) = $_[0] ;

#	$page =~ s/<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?P_[^>]*>/<!-- Hidden field removed -->/gi ;
	$page =~ s/<\s*INPUT\s+TYPE\s*=\s*"?HIDDEN"?\s+NAME\s*=\s*"?Q_[^>]*>/<!-- Hidden field removed -->/gi ;

	return $page ;
}

# Subroutine LockFile
#
# Creates a lock file that logically locks the given path. Returns the
# file handle of the open lock file.

sub LockFile
{
	local $path = $_[0] ;
	local $mode = $_[1] ;

	if ($E_useFlock eq 'Yes')
	{
		local $flockPath = $path . &SafeEval (&ExpandShortVarRefs ($E_flockFileExt)) ;
		local $flockFH = $flockPath ;
		
		# Open the lock file
		open ($flockFH, ">$flockPath") || &DieMsg ("Fatal Error",
																 "The script cannot process your survey because ".
																 "it cannot create or open the lock file (" . &HTMLEncodeText ($flockPath) . "): $! ($?).",
																 "Please contact this site's webmaster.") ;

		if (flock ($flockFH, $mode))
		{
			if ($E_test & 2)
			{
				local $fexistPath = $path . &SafeEval (&ExpandShortVarRefs ($E_fexistFileExt)) ;
				if ($mode == 2)
				{
					eval "use Fcntl qw(O_CREAT O_EXCL O_WRONLY) ;" ;
					&DieMsg ("Fatal Error", "$@", "Please contact this site's webmaster.") if ($@) ;

					local $fexistFH = $fexistPath ;
					if (sysopen ($fexistFH, $fexistPath, O_CREAT() | O_EXCL() | O_WRONLY())) { close $fexistFH ; }
					else
					{
						&DieMsg ("Fatal Error",
									"The script cannot process your survey because ".
									"it has encountered a problem with file locking: it has acquired an exclusive lock for the file (" . &HTMLEncodeText ($flockPath) . ") but cannot create the file (" . &HTMLEncodeText ($fexistPath) . "): $! ($?).",
									"Please contact this site's webmaster.") ;
					}
				}
				elsif (-e $fexistPath)
				{
					&DieMsg ("Fatal Error",
								"The script cannot process your survey because ".
								"it has encountered a problem with file locking: it has acquired a shared lock for the file (" . &HTMLEncodeText ($flockPath) . ") but found that the file (" . &HTMLEncodeText ($fexistPath) . ") exists.",
								"Please contact this site's webmaster.") ;
				}
			}
		}
		else
		{
			&DieMsg (&SafeEval (qq/"$E_msgSysSystemBusy"/), &SafeEval (qq/"$E_msgSysCantLock"/), &SafeEval (qq/"$E_msgSysBackButton"/)) ;
		}
		return ($flockFH, $path, $mode) ;
	}
	else
	{
		eval "use Fcntl qw(O_CREAT O_EXCL O_WRONLY) ;";
		&DieMsg ("Fatal Error", "$@", "Please contact this site's webmaster.") if ($@) ;

		local $fexistTimeOutThreshold = &SafeEval (&ExpandShortVarRefs ($E_fexistTimeOutThreshold)) ;
		local $fexistWaitToTryAgain = &SafeEval (&ExpandShortVarRefs ($E_fexistWaitToTryAgain)) ;
		local $fexistPath = $path . &SafeEval (&ExpandShortVarRefs ($E_fexistFileExt)) ;
		local $fexistFH = $fexistPath ;
		local $tmStart = time ;
		local $tmLast = $tmStart ;
		while (!sysopen ($fexistFH, $fexistPath, O_CREAT() | O_EXCL() | O_WRONLY()))
		{
			if ($fexistWaitToTryAgain > 0)
			{
				while (1)
				{
					local $tm = time ;
					last if ($tm < $tmLast || ($tm - $tmLast >= $fexistWaitToTryAgain) || ($tm < $tmStart) || ($tm - $tmStart >= $fexistTimeOutThreshold)) ;
				}
			}
			$tmLast = time ;
			&DieMsg (&SafeEval (qq/"$E_msgSysSystemBusy"/), &SafeEval (qq/"$E_msgSysCantLock"/), &SafeEval (qq/"$E_msgSysBackButton"/)) if (($tmLast < $tmStart) || ($tmLast - $tmStart >= $fexistTimeOutThreshold)) ;
		}
		close $fexistFH ;
		return ($path, $path, $mode) ;
	}
}

# Subroutine UnlockFile
#
# Closes the lock file. This unlocks the file.

sub UnlockFile
{
	local $fh = $_[0] ;
	local $path = $_[1] ;
	local $mode = $_[2] ;

	if ($E_test & 4)
	{
		local $test4WaitToUnlock = &SafeEval (&ExpandShortVarRefs ($E_test4WaitToUnlock)) ;
		if ($test4WaitToUnlock > 0)
		{
			local $tmStart = time ;
			while (1)
			{
				local $tm = time ;
				last if ($tm < $tmStart || ($tm - $tmStart >= $test4WaitToUnlock)) ;
			}
		}
	}
	if ($E_useFlock eq 'Yes')
	{
		if ($E_test & 2)
		{
			if ($mode == 2)
			{
				local $fexistPath = $path . &SafeEval (&ExpandShortVarRefs ($E_fexistFileExt)) ;
				unlink ($fexistPath) > 0 || &DieMsg ("Fatal Error",
																 "The script cannot process your survey because ".
																 "it failed to find and delete the lock file (" . &HTMLEncodeText ($fexistPath) . "): $! ($?).",
																 "Please contact this site's webmaster.") ;
			}
		}
		close ($fh) ;
	}
	else
	{
		local $fexistPath = $path . &SafeEval (&ExpandShortVarRefs ($E_fexistFileExt)) ;
		unlink ($fexistPath) > 0 || &DieMsg ("Fatal Error",
														 "The script cannot process your survey because ".
														 "it failed to find and delete the lock file (" . &HTMLEncodeText ($fexistPath) . "): $! ($?).",
														 "Please contact this site's webmaster.") ;
	}
}

# Subroutine GetNextRecID
#
# Increments the record id number in the record id file. The number
# determines the id for the next record in the data file. Returns the
# next record id.

sub GetNextRecID
{
	local $path = $_[0] ;
	local $recIDVar = $_[1] ;
	local $recCntVar = $_[2] ;
	local $recIDPath = $path . &SafeEval (&ExpandShortVarRefs ($E_idFileExt)) ;
	local $recIDFH = $recIDPath ;
	local $nextRecID = &MaybeFixDataFile ($path, $recIDVar, $recCntVar, 0) ;

	if (open ($recIDFH, "<$recIDPath"))							# Open the record id file for reading
	{
		local $recID = <$recIDFH> ;								# Get the record id
		close ($recIDFH) ;											# Close the file
		$nextRecID = $recID if ($recID > $nextRecID) ;		# Use the larger of the two record ids
	}

	$nextRecID++;														# Increment the record id
	$recIDFH = $recIDPath ;
	if (open ($recIDFH, ">$recIDPath"))							# Truncate the record id file
	{
		print ($recIDFH $nextRecID) || &DieMsg () ;			# Write the new record id
		close ($recIDFH) ;											# Close the file
	}
	else
	{
		&DieMsg ("Fatal Error",
					"The script cannot process your survey because it cannot create or write to the record id file (" . &HTMLEncodeText ($recIDPath) . "): $! ($?).",
					"Please contact this site's webmaster.") ;
	}
	return $nextRecID ;
}

# Subroutine MaybeUpdateRecIDFile
#
# Updates the record id file if the given record id is larger than the
# value already in the file. Returns the record id from the file.

sub MaybeUpdateRecIDFile
{
	local $path = $_[0] ;
	local $recID = $_[1] ;
	local $recIDInFile = 0 ;
	local $recIDPath = $path . &SafeEval (&ExpandShortVarRefs ($E_idFileExt)) ;
	local $recIDFH = $recIDPath ;

	if (open ($recIDFH, "<$recIDPath"))							# Open the record id file for reading
	{
		$recIDInFile = <$recIDFH> ;								# Get the record id
		close ($recIDFH) ;											# Close the file
	}

	if ($recID > $recIDInFile)										# Is the record id larger than the one in the file?
	{
		$recIDInFile = $recID ;										# Use the new record id
		$recIDFH = $recIDPath ;
		if (open ($recIDFH, ">$recIDPath"))						# Truncate the record id file
		{
			print ($recIDFH $recIDInFile) || &DieMsg () ;	# Write the new record id
			close ($recIDFH) ;										# Close the file
		}
		else
		{
			&DieMsg ("Fatal Error",
						"The script cannot process your survey because it cannot create or write to the record id file (" . &HTMLEncodeText ($recIDPath) . "): $! ($?).",
						"Please contact this site's webmaster.") ;
		}
	}
	return $recIDInFile ;											# Return the record id in the file
}

# Subroutine MaybeFixDataFile
#
# Changes the data file to include columns for the record id and
# counter. Returns the largest record id found in the data file.
# Returns 0 if decided not to calculate the largest record id.
# Dies if the data file cannot be changed to include the columns.

sub MaybeFixDataFile
{
	local $path = $_[0] ;
	local $recIDVar = $_[1] ;
	local $recCntVar = $_[2] ;
	local $bMaybeUpdateRecIDFile = $_[3] ;
	local $recID = 0 ;

	local $pathExists = &CheckPathExists ($path) ;
	if ($pathExists eq "true")
	{
		local $fileHandle = $path ;
		if (open ($fileHandle, "<$path"))				# Open the data file read-only
		{
			local ($vlst) = join (',', @varList) ;		# Check the variable list in the data file
			local $vlstLength = length ($vlst) ;
			local $gotVlst = <$fileHandle> ;				# Read the variable list from the data file

			chomp ($gotVlst) ;								# Remove the line break (Perl 5)
			$gotVlst =~ s/\r$// ;							# A carriage return character could still be at the end of the line
			local $gotVlstLength = length ($gotVlst) ;

			close ($fileHandle) ;							# Close the file

			if (!($gotVlstLength == 0 || $gotVlst eq '') && ($gotVlstLength != $vlstLength || $gotVlst ne $vlst))
			{
				if ((($recIDVar . ',' . $recCntVar . ',' . $gotVlst) eq $vlst) || (($recIDVar . ',' . $gotVlst) eq $vlst) || (($recCntVar . ',' . $gotVlst) eq $vlst))
				{
					$recID = &PrependColumnsToDataFile ($path, $recIDVar, $recCntVar) ;
					&MaybeUpdateRecIDFile ($path, $recID) if ($bMaybeUpdateRecIDFile) ;
					# Maybe create an index file
					{
						local (@qryVarValueKeys) = keys %qryVarValues ;
						local (@qryVarUTestKeys) = keys %qvyVarUTests ;
						&WriteIndexFile ($path) if ($E_useIndexFile eq 'Yes' && $#qryVarValueKeys >= 0 && $#qryVarUTestKeys < 0 && $E_matchEmpty ne 'Yes' && $E_recIDVar ne '' && !defined $qryVarValues{$E_recIDVar}) ;
					}
				}
				else
				{
					&DieMsg ("Fatal Error",
								"The script cannot process your survey. The data file (" . &HTMLEncodeText ($path) . ") is either intended for another Web survey or contains corrupted or out-of-date data.",
								"Please contact this site's webmaster.") ;
				}
			}
		}
		else
		{
			&DieMsg ("Fatal Error",
						"The script cannot process your survey because it cannot open the data file (" . &HTMLEncodeText ($path) . ") for reading: $! ($?).",
						"Please contact this site's webmaster.") ;
		}
	}
	return $recID ;
}

# Subroutine PrependColumnsToDataFile
#
# Adds the given id and count columns to the data file. Returns the largest id
# generated. Dies if encounters an error.

sub PrependColumnsToDataFile
{
	local $path = $_[0] ;
	local $recIDVar = $_[1] ;
	local $recCntVar = $_[2] ;
	local $recID = 0 ;

	if ($recIDVar ne '' && $recCntVar ne '')
	{
		local $fileHandle = $path ;
		local (@recArray) ;

		if (open ($fileHandle, "<$path"))				# Open the data file read-only
		{
			# Read all records into an array
			while (defined ($_ = <$fileHandle>))		# Read the next record
			{
				push (@recArray, $_) ;
			}
			close ($fileHandle) ;
		}
		else
		{
			&DieMsg ("Fatal Error",
						"The script cannot process your survey because it cannot open the file (" . &HTMLEncodeText ($path) . ") for reading: $! ($?).",
						"Please contact this site's webmaster.") ;
		}

		if ($#recArray >= 0)
		{
			# Prepend all records with the $recIDVar column
			if ($recIDVar ne '' && $recCntVar ne '')
			{
				$recArray[0] = $recIDVar . ',' . $recCntVar . ',' . $recArray[0] ;
			}
			elsif ($recIDVar ne '')
			{
				$recArray[0] = $recIDVar . ',' . $recArray[0] ;
			}
			else
			{
				$recArray[0] = $recCntVar . ',' . $recArray[0] ;
			}

			for (local $iii = 1; $iii <= $#recArray; $iii++)
			{
				if ($recIDVar ne '' && $recCntVar ne '')
				{
					$recArray[$iii] = ++$recID . ',' . '0,' . $recArray[$iii] ;
				}
				elsif ($recIDVar ne '')
				{
					$recArray[$iii] = ++$recID . ',' . $recArray[$iii] ;
				}
				else
				{
					$recArray[$iii] = '0,' . $recArray[$iii] ;
				}
			}

			# Reopen the file for truncating
			$fileHandle = $path ;
			if (open ($fileHandle, ">$path"))
			{
				# Write the array to the data file
				print ($fileHandle @recArray) || &DieMsg () ;
				close ($fileHandle) ;
			}
			else
			{
				&DieMsg ("Fatal Error",
							"The script cannot process your survey because it cannot open the file (" . &HTMLEncodeText ($path) . ") for writing: $! ($?).",
							"Please contact this site's webmaster.") ;
			}
		}
	}
	return $recID ;
}

# Subroutine GetVarListPos
#
# Returns the position of a variable name in the @varList array.
# Returns -1 if not found.

sub GetVarListPos
{
	local ($varName) = $_[0] ;
	local ($pos) = -1 ;

	for (local ($iii) = 0 ; $iii <= $#varList; $iii++)
	{
		if ($varList[$iii] eq $varName)
		{
			$pos = $iii ;
			last ;
		}
	}
	return $pos ;
}

# Subroutine WriteDataFile_2
#
# Writes the contents of @varValues to the given data file.
# See WriteDataFile for more information.

sub WriteDataFile_2
{
	local $path = $_[0] ;					# Path to save the data
	local $bFinal = $_[1] ;					# Final submission?
	local (@svv) = @varValues;				# Save @varValues

	if ($E_useRecCnt eq 'Yes' && $E_recCntVar ne '')	# Use record counts?
	{
		local $pos = GetVarListPos ($E_recCntVar) ;		# Get the record count variable position
		if ($pos >= 0)
		{
			local $recCnt = 0 ;
			local $bookmarkPageNum = -1 ;
			if ($varValues[$pos] =~ m/^\d+$E_decimalPoint\d+$/)
			{
				($recCnt, $bookmarkPageNum) = ($varValues[$pos] =~ m/^(\d+)$E_decimalPoint(\d+)$/) ;
			}
			else
			{
				$recCnt = $varValues[$pos] ;
			}
			
			if ($bFinal eq 'No')
			{
				$recCnt-- ;						# Subtract 1 from the record count
			}
			else
			{
				$bookmarkPageNum = -1 ;		# Remove possible bookmark
			}

			if ($bookmarkPageNum == -1)
			{
				$varValues[$pos] = $recCnt ;
			}
			else
			{
				$varValues[$pos] = $recCnt . $E_decimalPoint . $bookmarkPageNum;
			}
		}
	}
	&PrepareVarValues ;							# Prepare @varValues for writing to the data file
	local $err = &WriteDataFile ($path) ;	# Append to or update the data file
	&MaybeSendMail if ($err == 0 && $bFinal ne 'No') ; # Send notification e-mail?

	@varValues = @svv;						# Restore @varValues
	return $err ;								# 0 indicates success.
}

#
## Safe Evaluation Functions
#

# Subroutine SafeEval
#
# This function first checks to determine if the expression is safe. If
# not safe, this function halts with a message. Otherwise, it evaluates
# the expression and returns the result.

sub SafeEval
{
	local $expr = $_[0] ;
	&DieMsg ("Fatal Error", "Error in expression \"" . &HTMLEncodeText ($expr) . "\": contains one or more unrecognized commands.", "Please contact this site's webmaster") if (!&IsExprSafe ($expr)) ;
	return eval ($expr) ;
}

# Subroutine IsExprSafe
#
# This function returns 1 if the expression is safe. Otherwise it
# returns 0. No explanation is offered.

sub IsExprSafe
{
	local $expr = $_[0] ;											# Expression
	local $safe = 1;

	# Handle carriage returns/linefeeds
	$expr =~ s/\r\n/ /g ;											# Replace all carriage returns/linefeeds with a space
	$expr =~ s/\r/ /g ;												# Replace all carriage returns with a space
	$expr =~ s/\n/ /g ;												# Replace all linefeeds with a space
	$expr =~ s/\t/ /g ;												# Replace all tabs with a space
	$expr =~ s/\f/ /g ;												# Replace all formfeeds with a space

	# Handle single quotation marks
	$expr =~ s/\\'/1/g ;												# Replace all occurrences of \' with 1
	$expr =~ s/{'.*?'}/{1}/g ;										# Replace all occurrences of {'...'} with {1}
	$expr =~ s/'.*?'/ 1 /g ;										# Replace all occurrences of '...' with 1

	# Allowed global associative arrays
	$expr =~ s/\$ansVarValues{[a-zA-Z_0-9\$#]+}/\$1{}/g ;	# Replace all occurrences of $ansVarValues{...} with $1{}
	$expr =~ s/\$fwdVarValues{[a-zA-Z_0-9\$#]+}/\$1{}/g ;	# Replace all occurrences of $fwdVarValues{...} with $1{}
	$expr =~ s/\$defVarValues{[a-zA-Z_0-9\$#]+}/\$1{}/g ;	# Replace all occurrences of $defVarValues{...} with $1{}
	$expr =~ s/\$evlVarValues{[a-zA-Z_0-9\$#]+}/\$1{}/g ;	# Replace all occurrences of $evlVarValues{...} with $1{}
	$expr =~ s/\$qryVarValues{[a-zA-Z_0-9\$#]+}/\$1{}/g ;	# Replace all occurrences of $qryVarValues{...} with $1{}
	$expr =~ s/\$qryVarUTests{[a-zA-Z_0-9\$#]+}/\$1{}/g ;	# Replace all occurrences of $qryVarUTests{...} with $1{}
	$expr =~ s/\$recVarValues{[a-zA-Z_0-9\$#]+}/\$1{}/g ;	# Replace all occurrences of $recVarValues{...} with $1{}
	$expr =~ s/\$insVarValues{[a-zA-Z_0-9\$#]+}/\$1{}/g ;	# Replace all occurrences of $insVarValues{...} with $1{}
	$expr =~ s/\$varValues{[a-zA-Z_0-9\$#]+}/\$1{}/g ;		# Replace all occurrences of $varValues{...} with $1{}
	$expr =~ s/\$recValue{[a-zA-Z_0-9\$#]+}/\$1{}/g ;		# Replace all occurrences of $recValue{...} with $1{}
	$expr =~ s/\$rec{[a-zA-Z_0-9\$#]+}/\$1{}/g ;				# Replace all occurrences of $rec{...} with $1{}
	$expr =~ s/\$globalFields{[a-zA-Z_0-9\$#]+}/\$1{}/g ;	# Replace all occurrences of $globalFields{...} with $1{}
	$expr =~ s/\$raw_data{[a-zA-Z_0-9\$#]+}/\$1{}/g ;		# Replace all occurrences of $raw_data{...} with $1{}

	# Handle double quotation marks
	$expr =~ s/\\"/1/g ;												# Replace all occurrences of \" with 1
	$expr =~ s/".*?\@[\w\s]*?{[^}]+?}.*?"/-x-/g ;			# Replace all occurrences of "...@abc{...}..." with -x-
	$expr =~ s/".*?\$[\w\s]*?{[^}]+?}.*?"/-x-/g ;			# Replace all occurrences of "...$abc{...}..." with -x-
	$expr =~ s/".*?"/ 1 /g ;										# Replace all occurrences of "..." with 1

	# Disallowed constructs
	$expr =~ s/<[a-zA-Z_0-9\*\.\$\/\[\]]*>/-x-/g ;			# Replace all occurrences of <> with -x-
	$expr =~ s/->[\s]*?\([^\)]*?\)/-x-/g ;						# Replace all occurrences of ->(...) with -x-
	$expr =~ s/{[^}]*?}[\s]*?\([^\)]*?\)/-x-/g ;				# Replace all occurrences of {...}(...) with -x-
	$expr =~ s/\&\&/ 1 /g ;											# Replace all occurrences of && with 1
	$expr =~ s/\&[\s]*?\$/-x-/g ;									# Replace all occurrences of &$ with -x-

	if ($expr =~ /[a-zA-Z]/)										# Are there any alpha characters?
	{
		# Allowed global variables
		$expr =~ s/\$rVal/\$1/g ;									# Replace all occurrences of $rVal with $1
		$expr =~ s/\$qVal/\$1/g ;									# Replace all occurrences of $qVal with $1

		# Allowed Functions
		$expr =~ s/localtime/1/g ;									# Replace all occurrences of localtime with 1
		$expr =~ s/gmtime/1/g ;										# Replace all occurrences of gmtime with 1
		$expr =~ s/local/1/g ;										# Replace all occurrences of local with 1
		$expr =~ s/rand/1/g ;										# Replace all occurrences of rand with 1
		$expr =~ s/int/1/g ;											# Replace all occurrences of int with 1
		$expr =~ s/length/1/g ;										# Replace all occurrences of length with 1
		$expr =~ s/rindex/1/g ;										# Replace all occurrences of rindex with 1
		$expr =~ s/index/1/g ;										# Replace all occurrences of index with 1
		$expr =~ s/my/1/g ;											# Replace all occurrences of my with 1
		$expr =~ s/ eq / 1 /g ;										# Replace all occurrences of eq with 1
		$expr =~ s/ ne / 1 /g ;										# Replace all occurrences of ne with 1
		$expr =~ s/uc /1 /g ;										# Replace all occurrences of uc with 1
		$expr =~ s/lc /1 /g ;										# Replace all occurrences of lc with 1
		$expr =~ s/split/1/g ;										# Replace all occurrences of split with 1
		$expr =~ s/join/1/g ;										# Replace all occurrences of join with 1
		$expr =~ s/s\/[a-zA-Z_0-9|\\\*\+\?\$\.\(\)]+\/[a-zA-Z_0-9|\\]*\/[gimosx]*/1/g ;	# Replace all occurrences of s/.../.../gimosx with 1
		$expr =~ s/m\/[a-zA-Z_0-9|\\\*\+\?\$\.\(\)]+\/[gimosx]*/1/g ;							# Replace all occurrences of m/.../gimosx with 1
		$expr =~ s/\[a-zA-Z_0-9\]/1/g ;							# Replace all occurrences of [a-zA-Z_0-9] with 1
		$expr =~ s/\[a-zA-Z\]/1/g ;								# Replace all occurrences of [a-zA-Z] with 1
		$expr =~ s/\[0-9\]/1/g ;									# Replace all occurrences of [0-9] with 1
		$expr =~ s/substr/1/g ;										# Replace all occurrences of substr with 1

		# Allowed extension functions
		$expr =~ s/XF_ASSIGNCVTOCV\s*\(/1(/g ;					# Replace all occurrences of XF_ASSIGNCVTOCV with 1
		$expr =~ s/XF_ASSIGNLVTOLV\s*\(/1(/g ;					# Replace all occurrences of XF_ASSIGNLVTOLV with 1
		$expr =~ s/XF_ASSIGNQVTOQV\s*\(/1(/g ;					# Replace all occurrences of XF_ASSIGNQVTOQV with 1
		$expr =~ s/XF_COUNT\s*\(/1(/g ;							# Replace all occurrences of XF_COUNT with 1
		$expr =~ s/XF_SUM\s*\(/1(/g ;								# Replace all occurrences of XF_SUM with 1
		$expr =~ s/XF_LT_NUM\s*\(/1(/g ;							# Replace all occurrences of XF_LT_NUM with 1
		$expr =~ s/XF_LT\s*\(/1(/g ;								# Replace all occurrences of XF_LT with 1
		$expr =~ s/XF_LE_NUM\s*\(/1(/g ;							# Replace all occurrences of XF_LE_NUM with 1
		$expr =~ s/XF_LE\s*\(/1(/g ;								# Replace all occurrences of XF_LE with 1
		$expr =~ s/XF_GT_NUM\s*\(/1(/g ;							# Replace all occurrences of XF_GT_NUM with 1
		$expr =~ s/XF_GT\s*\(/1(/g ;								# Replace all occurrences of XF_GT with 1
		$expr =~ s/XF_GE_NUM\s*\(/1(/g ;							# Replace all occurrences of XF_GE_NUM with 1
		$expr =~ s/XF_GE\s*\(/1(/g ;								# Replace all occurrences of XF_GE with 1
		$expr =~ s/XF_ENV\s*\([a-zA-Z_0-9]+\)/1(2)/g ;		# Replace all occurrences of XF_ENV(...) with 1
		$expr =~ s/XF_PERMUTE\s*\(/1(/g ;						# Replace all occurrences of XF_PERMUTE with 1
		$expr =~ s/XF_N2PAT\s*\(/1(/g ;							# Replace all occurrences of XF_N2PAT with 1
		$expr =~ s/XF_FACTORIAL\s*\(/1(/g ;						# Replace all occurrences of XF_FACTORIAL with 1

		$expr =~ s/XF_ABS\s*\(/1(/g ;								# Replace all occurrences of XF_ABS with 1
		$expr =~ s/XF_CEIL\s*\(/1(/g ;							# Replace all occurrences of XF_CEIL with 1
		$expr =~ s/XF_CONTAINS_RE\s*\(/1(/g ;					# Replace all occurrences of XF_CONTAINS_RE with 1
		$expr =~ s/XF_CONTAINS\s*\(/1(/g ;						# Replace all occurrences of XF_CONTAINS with 1
		$expr =~ s/XF_DIV\s*\(/1(/g ;								# Replace all occurrences of XF_DIV with 1
		$expr =~ s/XF_EQ_NUM\s*\(/1(/g ;							# Replace all occurrences of XF_EQ_NUM with 1
		$expr =~ s/XF_EQ\s*\(/1(/g ;								# Replace all occurrences of XF_EQ with 1
		$expr =~ s/XF_FLOOR\s*\(/1(/g ;							# Replace all occurrences of XF_FLOOR with 1
		$expr =~ s/XF_FORMAT_LOCALTIME\s*\(/1(/g ;			# Replace all occurrences of XF_FORMAT_LOCALTIME with 1
		$expr =~ s/XF_FORMAT_TIME\s*\(/1(/g ;					# Replace all occurrences of XF_FORMAT_TIME with 1
		$expr =~ s/XF_INDEX_RE\s*\(/1(/g ;						# Replace all occurrences of XF_INDEX_RE with 1
		$expr =~ s/XF_INDEX\s*\(/1(/g ;							# Replace all occurrences of XF_INDEX with 1
		$expr =~ s/XF_IS_FALSE_OR_NV\s*\(/1(/g ;				# Replace all occurrences of XF_IS_FALSE_OR_NV with 1
		$expr =~ s/XF_IS_MISSING\s*\(/1(/g ;					# Replace all occurrences of XF_IS_MISSING with 1
		$expr =~ s/XF_IS_TRUE_NOT_NV\s*\(/1(/g ;				# Replace all occurrences of XF_IS_TRUE_NOT_NV with 1
		$expr =~ s/XF_IS_TRUE_OR_NV\s*\(/1(/g ;				# Replace all occurrences of XF_IS_TRUE_OR_NV with 1
		$expr =~ s/XF_IS_VALID\s*\(/1(/g ;						# Replace all occurrences of XF_IS_VALID with 1
		$expr =~ s/XF_LEFT\s*\(/1(/g ;							# Replace all occurrences of XF_LEFT with 1
		$expr =~ s/XF_LENGTH\s*\(/1(/g ;							# Replace all occurrences of XF_LENGTH with 1
		$expr =~ s/XF_LIST_CONTAINS\s*\(/1(/g ;				# Replace all occurrences of XF_LIST_CONTAINS with 1
		$expr =~ s/XF_LIST_ELEMENT\s*\(/1(/g ;					# Replace all occurrences of XF_LIST_ELEMENT with 1
		$expr =~ s/XF_LIST_INDEX\s*\(/1(/g ;					# Replace all occurrences of XF_LIST_INDEX with 1
		$expr =~ s/XF_LIST_RANDOMIZE\s*\(/1(/g ;				# Replace all occurrences of XF_LIST_RANDOMIZE with 1
		$expr =~ s/XF_LIST_REMOVE\s*\(/1(/g ;					# Replace all occurrences of XF_LIST_REMOVE with 1
		$expr =~ s/XF_LIST_REVERSE\s*\(/1(/g ;					# Replace all occurrences of XF_LIST_REVERSE with 1
		$expr =~ s/XF_LIST_ROTATE\s*\(/1(/g ;					# Replace all occurrences of XF_LIST_ROTATE with 1
		$expr =~ s/XF_LIST_SIZE\s*\(/1(/g ;						# Replace all occurrences of XF_LIST_SIZE with 1
		$expr =~ s/XF_LIT_TO_QTY\s*\(/1(/g ;					# Replace all occurrences of XF_LIT_TO_QTY with 1
		$expr =~ s/XF_LOCALTIME_PART\s*\(/1(/g ;					# Replace all occurrences of XF_LOCALTIME_PART with 1
		$expr =~ s/XF_MAX\s*\(/1(/g ;								# Replace all occurrences of XF_MAX with 1
		$expr =~ s/XF_MEAN\s*\(/1(/g ;							# Replace all occurrences of XF_MEAN with 1
		$expr =~ s/XF_MIDSTR\s*\(/1(/g ;							# Replace all occurrences of XF_MIDSTR with 1
		$expr =~ s/XF_MIN\s*\(/1(/g ;								# Replace all occurrences of XF_MIN with 1
		$expr =~ s/XF_MODULO\s*\(/1(/g ;							# Replace all occurrences of XF_MODULO with 1
		$expr =~ s/XF_NEG\s*\(/1(/g ;								# Replace all occurrences of XF_NEG with 1
		$expr =~ s/XF_NE_NUM\s*\(/1(/g ;							# Replace all occurrences of XF_NE_NUM with 1
		$expr =~ s/XF_NE\s*\(/1(/g ;								# Replace all occurrences of XF_NE with 1
		$expr =~ s/XF_NOT\s*\(/1(/g ;								# Replace all occurrences of XF_NOT with 1
		$expr =~ s/XF_PERCENTAGE\s*\(/1(/g ;					# Replace all occurrences of XF_PERCENTAGE with 1
		$expr =~ s/XF_POWER\s*\(/1(/g ;							# Replace all occurrences of XF_POWER with 1
		$expr =~ s/XF_QTY_TO_LIT\s*\(/1(/g ;					# Replace all occurrences of XF_QTY_TO_LIT with 1
		$expr =~ s/XF_RAND\s*\(/1(/g ;							# Replace all occurrences of XF_RAND with 1
		$expr =~ s/XF_RATIO\s*\(/1(/g ;							# Replace all occurrences of XF_RATIO with 1
		$expr =~ s/XF_REPLACE_RE\s*\(/1(/g ;					# Replace all occurrences of XF_REPLACE_RE with 1
		$expr =~ s/XF_REPLACE\s*\(/1(/g ;						# Replace all occurrences of XF_REPLACE with 1
		$expr =~ s/XF_RIGHT\s*\(/1(/g ;							# Replace all occurrences of XF_RIGHT with 1
		$expr =~ s/XF_ROUND\s*\(/1(/g ;							# Replace all occurrences of XF_ROUND with 1
		$expr =~ s/XF_STRIP\s*\(/1(/g ;							# Replace all occurrences of XF_STRIP with 1
		$expr =~ s/XF_SUBSTR_RE\s*\(/1(/g ;						# Replace all occurrences of XF_SUBSTR_RE with 1
		$expr =~ s/XF_SUBSTR\s*\(/1(/g ;							# Replace all occurrences of XF_SUBSTR with 1
		$expr =~ s/XF_TOLOWER\s*\(/1(/g ;						# Replace all occurrences of XF_TOLOWER with 1
		$expr =~ s/XF_TOUPPER\s*\(/1(/g ;						# Replace all occurrences of XF_TOUPPER with 1
		$expr =~ s/XF_WEBSERVER_ENV\s*\(/1(/g ;				# Replace all occurrences of XF_WEBSERVER_ENV with 1

		$safe = 0 if ($expr =~ /[a-zA-Z]/) ;					# Are there any alpha characters left?
#		&DieMsg ("$_[0]", "|$expr|", "$safe") if (!$safe) ;
	}
	return $safe ;
}

#
## Configuration File Functions
#

# Subroutine ReadConfSection
#
# Reads a specific section of the configuration file, setting values in
# %raw_data.

sub ReadConfSection
{
	local $fileHandle = $_[0] ;						# File handle
	local $section = $_[1] ;							# Section to look for
	local $line = $_[2] ;								# Most recent line
	local $hashref = $_[3] ;

	if ($line eq '')
	{
		$line = <$fileHandle> ;							# Read the next line
	}

	if ($line ne '')
	{
		local $len = length ($section) + 2 ;		
		while (length ($line) < $len || substr ($line, 0, $len) ne "\[$section\]")	# Read until section
		{
			$line = <$fileHandle> ;						# Read the next line
			last if $line eq '' ;						# Stop if end of file
		}
		while ($line ne '')								# Read until end of file
		{
			$line = <$fileHandle> ;						# Read the next line

			last if $line eq '' ;						# Stop if end of file
			last if substr ($line, 0, 1) eq '[' ;	# Stop if new section

			if (substr ($line, 0, 1) ne ';')			# Ignore comment line
			{
				if ($line =~ /=/)							# Proper name=value form?
				{
					chomp ($line) ;						# Remove the line break (Perl 5)
					$line =~ s/\r$// ;					# A carriage return character could still be at the end of the line
					local ($name, $value) = split (/=/, $line, 2) ;
					${$hashref}{$name} = $value ;		# Assign the name and value to the hash
				}
			}
		}
	}

	return $line ;
}

# Subroutine ReadConfFile
#
# Reads the configuration file, setting values in %raw_data. Dies if
# there is an error.

sub ReadConfFile
{
	local $path = $_[0] ;
	local $hashref = $_[1] ;
	local $fileHandle = $path ;
	
	# Open the configuration file read-only
	open ($fileHandle, "<$path") || &DieMsg ("Fatal Error",
														  "The script cannot process your survey because ".
														  "it cannot open the configuration file (" . &HTMLEncodeText ($path) . ") for reading: $! ($?).",
														  "Please contact this site's webmaster.") ;

	# Read general name/value pairs
	local $section = 'SYSTEM' ;					# Read the SYSTEM section
	local $line = &ReadConfSection ($fileHandle, $section, '', $hashref) ;

	$section = 'MESSAGE' ;							# Read the MESSAGE section
	$line = &ReadConfSection ($fileHandle, $section, $line, $hashref) ;

	$section = 'COMMAND' ;							# Read the COMMAND section
	$line = &ReadConfSection ($fileHandle, $section, $line, $hashref) ;
	if ($line eq '')
	{
		# Seek to the beginning of the file
		seek ($fileHandle, 0, 0) || &DieMsg ("Fatal Error",
														 "The script cannot process your survey because ".
														 "it cannot seek to the beginning of the configuration file (" . &HTMLEncodeText ($path) . "): $! ($?).",
														 "Please contact this site's webmaster.") ;
	}

	$section = 'PATH' ;								# Read the PATH section
	$line = &ReadConfSection ($fileHandle, $section, $line, $hashref) ;

	# Read page-specific name/value pairs
	local $fileName = ${$hashref}{'E_reloadFileName'} ;
	if ($fileName eq '' && ${$hashref}{'E_1stFileName'} ne '')
	{
		$fileName = &SafeEval (${$hashref}{'E_1stFileName'}) ;
	}

	if ($fileName ne '')
	{
		&ReadConfSection ($fileHandle, $fileName, $line, $hashref);
	}

	# Close the file
	close ($fileHandle) ;

	return $fileName ;
}

# Subroutine ExtractKeyNames
#
# Returns an array that contains all of the names of the keys that
# match the given string.

sub ExtractKeyNames
{
	local $name = $_[0] ;		# Name of key to search for
	local $hashref = $_[1] ;	# Hash to search
	local $len = length ($name) ;		
	local (@keyList) = () ;
	local $key ;

	foreach $key ( keys %$hashref )
	{
		push (@keyList, $key) if (length ($key) >= $len && substr ($key, 0, $len) eq $name) ;
	}
	return (@keyList) ;
}

# Subroutine ExtractKeyValues
#
# Returns an array that contains all of the values of the keys that
# match the given string.

sub ExtractKeyValues
{
	local $name = $_[0] ;		# Name of key to search for
	local $hashref = $_[1] ;	# Hash to search
	local $len = length ($name) ;		
	local (@valueList) = () ;
	local $key ;

	foreach $key ( keys %$hashref )
	{
		push (@valueList, ${$hashref}{$key}) if (length ($key) >= $len && substr ($key, 0, $len) eq $name) ;
	}
	return (@valueList) ;
}

#
## SendMail Functions
#

# Subroutine ExpandShortVarRefs
#
# Replaces references to variables using $ + variable name with
# $varValues{'name'}.

sub ExpandShortVarRefs
{
	local $text = $_[0] ;

	local $pattern = '\$\w+' ;								# Search for all occurrences of $name
	local (@matchList) = ($text =~ m/$pattern/gi) ;	# Store search results in an array
	for (local $iii = 0; $iii < $#matchList + 1; $iii++)
	{
		local $name = substr ($matchList[$iii], 1) ;	# Extract the variable name
		local $pos = &GetVarListPos ($name) ;			# Is the variable in the list?
		if ($pos >= 0)
		{
			local $repl = '$varValues{\'' . $name . '\'}' ;
			$pattern = quotemeta ($matchList[$iii]) ;
			$text =~ s/$pattern/$repl/i ;
		}
	}

	return $text ;
}

# Subroutine ExpandShortVarRefs_AnsDefFwd
#
# Replaces references to variables using $ + variable name with
# $ansVarValues{'name'}, $defVarValues{'name'} or $fwdVarValues{'name'}.

sub ExpandShortVarRefs_AnsDefFwd
{
	local $text = $_[0] ;

	local $pattern = '\$\w+' ;								# Search for all occurrences of $name
	local (@matchList) = ($text =~ m/$pattern/gi) ;	# Store search results in an array
	for (local $iii = 0; $iii < $#matchList + 1; $iii++)
	{
		local $name = substr ($matchList[$iii], 1) ;	# Extract the variable name
		local $pos = &GetVarListPos ($name) ;			# Is the variable in the list?
		if ($pos >= 0)
		{
			local $repl ;
			if (defined ($ansVarValues{$name}))
			{
				$repl = '$ansVarValues{\'' . $name . '\'}' ;
			}
			elsif (defined ($insVarValues{$name}))
			{
				if (defined ($defVarValues{$name}))
				{
					$repl = '$defVarValues{\'' . $name . '\'}' ;
				}
				else
				{
					$repl = '$ansVarValues{\'' . $name . '\'}' ;
				}
			}
			else
			{
				$repl = '$fwdVarValues{\'' . $name . '\'}' ;
			}
			$pattern = quotemeta ($matchList[$iii]) ;
			$text =~ s/$pattern/$repl/i ;
		}
	}

	return $text ;
}

# Subroutine EvalShortVarRefs
#
# Replaces references to variables using $ + variable name with
# $varValues{'name'}.

sub EvalShortVarRefs
{
	local $text = $_[0] ;

	local $pattern = '\$\w+' ;								# Search for all occurrences of $name
	local (@matchList) = ($text =~ m/$pattern/gi) ;	# Store search results in an array
	for (local $iii = 0; $iii < $#matchList + 1; $iii++)
	{
		local $name = substr ($matchList[$iii], 1) ;	# Extract the variable name
		local $pos = &GetVarListPos ($name) ;			# Is the variable in the list?
		if ($pos >= 0)
		{
			local $repl = $varValues{$name} ;
			$pattern = quotemeta ($matchList[$iii]) ;
			$text =~ s/$pattern/$repl/i ;
		}
	}

	return $text ;
}

# Subroutine MaybeSendMail
#
# Sends a custom mail message.

sub MaybeSendMail
{
	local $err = 0 ;
	if ($E_sendMail ne '' && $E_sendMailProgTo ne '' && $E_sendMailMsgTo ne '')
	{
		local $expr = $E_sendMail ;
		local $sm = &SafeEval (&ExpandShortVarRefs ($expr)) ;
		&DieMsg ("Fatal Error", "Error in expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") if ($@) ;

		if ($sm eq 'Yes')
		{
			local $smProg = '' ;
			if ($E_sendMailUseEnv eq 'Yes')
			{
				local $smEnv = &SafeEval (&ExpandShortVarRefs ($E_sendMailEnv)) ;
				$smProg = &GetServerVariable ($E_sendMailEnvPrefix . $smEnv) if ($smEnv ne '') ;
			}
			else
			{
				$smProg = &SafeEval (&ExpandShortVarRefs ($E_sendMailProg)) ;
			}
			if ($smProg ne '')
			{
				$expr = $E_sendMailErrorFatal ;
				local $smErrorFatal = &SafeEval (&ExpandShortVarRefs ($expr)) ;
				&DieMsg ("Fatal Error", "Error in expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") if ($@) ;

				open (MAIL, "|$smProg") || ($smErrorFatal ne 'Yes') || &DieMsg ("Fatal Error", "The script encountered an error starting the e-mail program (" . &HTMLEncodeText ($smProg) . "): $! ($?). ", "Please contact this site's webmaster.") ;
				{
					local $smTo = '';
					local $smCC = '';
					local $smBCC = '';
					local $smFrom = '';
					local $smDate = '';
					local $smSubject = '';
					local $smBody = '';
					local $smLine = '' ;

					$smTo = &SafeEval (&ExpandShortVarRefs ($E_sendMailMsgTo)) if ($E_sendMailProgTo ne '' && $E_sendMailMsgTo ne '') ;
					$smCC = &SafeEval (&ExpandShortVarRefs ($E_sendMailMsgCC)) if ($E_sendMailProgCC ne '' && $E_sendMailMsgCC ne '') ;
					$smBCC = &SafeEval (&ExpandShortVarRefs ($E_sendMailMsgBCC)) if ($E_sendMailProgBCC ne '' && $E_sendMailMsgBCC ne '') ;
					$smFrom = &SafeEval (&ExpandShortVarRefs ($E_sendMailMsgFrom)) if ($E_sendMailProgFrom ne '' && $E_sendMailMsgFrom ne '') ;
					$smDate = &SafeEval (&ExpandShortVarRefs ($E_sendMailMsgDate)) if ($E_sendMailProgDate ne '' && $E_sendMailMsgDate ne '') ;
					$smSubject = &SafeEval (&ExpandShortVarRefs ($E_sendMailMsgSubj)) if ($E_sendMailProgSubj ne '' && $E_sendMailMsgSubj ne '') ;
					if ($E_sendMailProgBody ne '' && ($E_sendMailMsgBody ne '' || $E_sendMailMsgBodyFile ne ''))
					{
						local $vn = join (',', @varList) ;
						local $vv = join (',', @varValues) ;
						local $vt = '' ;
						for (local $iii = 0 ; $iii <= $#varList; $iii++)
						{
							$vt .= "$varList[$iii]: $varValues[$iii]\n" ;
						}
						if ($E_sendMailMsgBody ne '')
						{
							$smBody = &SafeEval (&ExpandShortVarRefs ($E_sendMailMsgBody)) ;
						}
						else
						{
							$smBody = &ReadTextFile (&SafeEval (&ExpandShortVarRefs ($E_sendMailMsgBodyFile))) ;
							$smBody = &EvalShortVarRefs ($smBody) ;
						}
					}

					if ($smSubject ne '')
					{
						$smLine .= &SafeEval ($E_sendMailProgSubj) ;
					}
					if ($smFrom ne '')
					{
						$smLine .= &SafeEval ($E_sendMailProgDate) ;
					}
					if ($smFrom ne '')
					{
						$smLine .= &SafeEval ($E_sendMailProgFrom) ;
					}
					if ($smTo ne '')
					{
						$smLine .= &SafeEval ($E_sendMailProgTo) ;
					}
					if ($smCC ne '')
					{
						$smLine .= &SafeEval ($E_sendMailProgCC) ;
					}
					if ($smBCC ne '')
					{
						$smLine .= &SafeEval ($E_sendMailProgBCC) ;
					}
					if ($smBody ne '')
					{
						$smLine .= &SafeEval ($E_sendMailProgBody) ;
					}
					print MAIL "$smLine" if ($smLine ne '') ;
				}
				close (MAIL) || ($smErrorFatal ne 'Yes') || &DieMsg ("Fatal Error", "The script encountered an error stopping the e-mail program (" . &HTMLEncodeText ($smProg) . "): $! ($?). ", "Please contact this site's webmaster.") ;
			}
		}
	}
	
	return $err ;
}

# Subroutine MakeVPOS
#
# This function returns an associative array of offsets for the
# passed in array of variables. It uses the vlst associative array,
# which it assumes has already been prepared.

sub MakeVPOS
{
	my (@vs) = @_ ;
	my (%vp) = () ;

	# Get the offsets of the referenced variables
	if ($#vs >= 0)
	{
		my $v ;
		foreach $v (@vs)
		{
			for (my $iii = 0 ; $iii <= $#vlst ; $iii++)
			{
				my $name = 'V_' . $vlst[$iii] ;
				if ($name eq $v)
				{
					$vp{$v} = $iii ;
					last ;
				}
			}
		}
	}
	return (%vp) ;
}

# Subroutine ArrayReverse
#
# Reverses the array in place.

sub ArrayReverse
{
	my ($array) = shift ;
	my $jjj = 0 ;
	for (my $iii = @$array - 1; $iii > $jjj; $iii--)
	{
		@$array[$iii,$jjj] = @$array[$jjj,$iii] ;
		$jjj++ ;
	}
}

# Subroutine ArrayRotate
#
# Rotates the array in place.

sub ArrayRotate
{
	my ($array) = shift ;
	my $n = shift ;
	@$array = split (/,/, &XF_PERMUTE ($n, join (',', @$array).',')) ;	# Permute the array
}

# Subroutine ListReorder
#
# This function returns the list all or partly reordered. The first
# argument is the list, the second is a list of elements to reorder.
# The third argument is a list of separators. The fourth argument is
# the function to call to reorder an array version of all or part of
# the list. The fifth argument is a parameter to pass to the array
# reorder function.

sub ListReorder
{
	my $l = ($#_ >= 0 ? $_[0] : '') ;
	my $f = ($#_ >= 1 ? $_[1] : '') ;
	my $s = ($#_ >= 2 ? $_[2] : ',') ;
	my $z = ($#_ >= 3 ? $_[3] : \&ArrayShuffle) ;
	my $p = ($#_ >= 4 ? $_[4] : '') ;
	my @r = split (/[$s]/, $l, length ($l) + 1) ;
	if ($#r >= 0)
	{
		my @fr = split (/[$s]/, $f, length ($f) + 1) ;
		if ($#fr < 0)
		{
			&$z (\@r, $p) ;	# Reorder the array
		}
		elsif ($#fr > 0)
		{
			for (my $o = 0; $o <= ($#fr - 1) / 2; $o++)
			{
				if ($fr[$o * 2] > $fr[($o * 2) + 1])
				{
					my $o2 = $fr[$o * 2] ;
					$fr[$o * 2] = $fr[($o * 2) + 1] ;
					$fr[($o * 2) + 1] = $o2 ;
				}
			}
			if ($#fr >= 3)
			{
				# Sort the pairs into a temporary array
				my @xfr = () ;
				while ($#fr >= 1)
				{
					# Sort by finding the smallest pair starting number
					my $xn = 0 ;
					my $xv = $fr[0] ;
					for (my $x = 1; $x <= ($#fr - 1) / 2; $x++)
					{
						if ($fr[$x * 2] < $xv)
						{
							$xn = $x;
							$xv = $fr[$x * 2];
						}
					}
					# Remove and add the smallest pair
					push (@xfr, splice (@fr, $xn * 2, 1)) ;
					push (@xfr, splice (@fr, $xn * 2, 1)) ;
				}
				# Copy the sorted array
				@fr = @xfr ;
			}
			# Create an array to reorder
			my @t = () ;
			{
				for (my $i = 0; $i <= ($#fr - 1) / 2; $i++)
				{
					push (@t, $i) if ($fr[$i * 2] > 0 && $fr[($i * 2) + 1] <= $#r + 1 && $fr[$i * 2] <= $fr[($i * 2) + 1] && ($i == 0 || $fr[$i * 2] > $fr [(($i - 1) * 2) + 1])) ;
				}
			}
			if ($#t == ($#fr - 1) / 2)
			{
				&$z (\@t, $p) ;	# Reorder the array
				my @r2 = @r ;
				my @fr2 = @fr ;
				for (my $j = 0; $j <= $#t; $j++)
				{
					# Pairs must be sorted for this to work
					for (my $k = 0; $k <= ($fr[($t[$j] * 2) + 1] - $fr[$t[$j] * 2]); $k++)
					{
						$r2[$fr2[$j * 2] - 1 + $k] = $r[$fr[$t[$j] * 2] - 1 + $k] ;
					}

					my $d = (($fr[($t[$j] * 2) + 1] - $fr[$t[$j] * 2]) - ($fr2[($j * 2) + 1] - $fr2[$j * 2])) ;
					if ($d != 0)
					{
						for (my $l = 0; $l <= ($#fr2 - 1) / 2; $l++)
						{
							if ($fr2[$l * 2] > $fr2[$j * 2])
							{
								$fr2[$l * 2] += $d ;
								$fr2[($l * 2) + 1] += $d ;
							}
						}
					}
				}
				@r = @r2 ;
			}
		}
	}
	return $#r >= 0 ? join (substr ($s, 0, 1), @r) : '' ;
}

#
## Extension Functions
#

# Subroutine XF_ASSIGNCVTOCV
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the second parameter.

sub XF_ASSIGNCVTOCV
{
	return ($_[1]) ;
}

# Subroutine XF_ASSIGNLVTOLV
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the second parameter.

sub XF_ASSIGNLVTOLV
{
	return ($_[1]) ;
}

# Subroutine XF_ASSIGNQVTOQV
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the second parameter.

sub XF_ASSIGNQVTOQV
{
	return ($_[1]) ;
}

# Subroutine XF_COUNT
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the number of records for which
# the given expression is true. The expression must use the
# %recValue associative array to test the values of each record.

sub XF_COUNT
{
	my $expr = $_[0] ;
	my $path = $E_dataFileName ;
	my $nResult = 0 ;

	if ($path ne '')
	{
		# Does the file exist?
		if (&CheckPathExists ($path) eq 'true')
		{
			# Wait for a shared lock
			local ($lockHandle, $lockPath, $lockMode) = &LockFile ($path, 1);

			# Open the data file for reading
			local $fileHandle = &OpenDataFileReadOnly ($path) ;

			# Read the first record (list of variable names)
			my $recData = &ReadDataFileRecord ($fileHandle) ;
			if ($recData ne '')
			{
				# Load the list of variable names into an array
				local (@vlst) = split (/,/, $recData) ;

				# Extract referenced variables from the expression
				my $pattern = 'V_[a-zA-Z_0-9\$#]*' ;
				my (@vars) = ($expr =~ m/$pattern/gi) ;
				my (%vpos) = MakeVPOS (@vars) ;

				while ($recData ne '')
				{
					# Read the next record
					$recData = &ReadDataFileRecord ($fileHandle) ;
					if ($recData ne '')
					{
						# Split into an associative array of the referenced variables' values
						local (%recValue) = &RecordToValuesList ($recData, \%vpos) ;

						# Evaluate the expression
						# The expression can use the %recValue associate array
						my $bMatch = &SafeEval ($expr) ;
						if ($@)
						{
							&DieMsg ("Fatal Error", "Error in expression \"" . &HTMLEncodeText ($expr) . "\": " . $@, "Please contact this site's webmaster.") ;
						}
						elsif ($bMatch)
						{
							# Increment the number of matches
							$nResult++;
						}
					}
				}
			}

			# Close the data file			
			close ($fileHandle) ;

			# Release the shared lock			
			&UnlockFile ($lockHandle, $lockPath, $lockMode) ;
		}
	}
	return $nResult ;
}

# Subroutine XF_SUM
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the sum of the values of the
# variable for each record for which the given expression is true.
# The expression must use the %recValue associative array to test the
# values of each record.

sub XF_SUM
{
	my $expr1 = $_[0] ;
	my $expr2 = $_[1] ;
	my $path = $E_dataFileName ;
	my $nResult = 0 ;

	if ($path ne '')
	{
		# Does the file exist?
		if (&CheckPathExists ($path) eq 'true')
		{
			# Wait for a shared lock
			local ($lockHandle, $lockPath, $lockMode) = &LockFile ($path, 1);

			# Open the data file for reading
			local $fileHandle = &OpenDataFileReadOnly ($path) ;

			# Read the first record (list of variable names)
			my $recData = &ReadDataFileRecord ($fileHandle) ;
			if ($recData ne '')
			{
				# Load the list of variable names into an array
				local (@vlst) = split (/,/, $recData) ;

				# Extract referenced variables from the expression
				my $exprs = $expr1 . '|' . $expr2 ;
				my $pattern = 'V_[a-zA-Z_0-9\$#]*' ;
				my (@vars) = ($exprs =~ m/$pattern/gi) ;
				my (%vpos) = MakeVPOS (@vars) ;

				while ($recData ne '')
				{
					# Read the next record
					$recData = &ReadDataFileRecord ($fileHandle) ;
					if ($recData ne '')
					{
						# Split into an associative array of the referenced variables' values
						local (%recValue) = &RecordToValuesList ($recData, \%vpos) ;

						# Evaluate the conditional expression
						# The expression can use the %recValue associate array
						my $bMatch = &SafeEval ($expr2) ;
						if ($@)
						{
							&DieMsg ("Fatal Error", "Error in expression \"" . &HTMLEncodeText ($expr2) . "\": " . $@, "Please contact this site's webmaster.") ;
						}
						elsif ($bMatch)
						{
							# Add to the total
							my $nValue = &SafeEval ($expr1) ;
							if ($@)
							{
								&DieMsg ("Fatal Error", "Error in expression \"" . &HTMLEncodeText ($expr1) . "\": " . $@, "Please contact this site's webmaster.") ;
							}
							else
							{
								$nResult += $nValue ;
							}
						}
					}
				}
			}

			# Close the data file			
			close ($fileHandle) ;

			# Release the shared lock			
			&UnlockFile ($lockHandle, $lockPath, $lockMode) ;
		}
	}
	return $nResult ;
}

# Subroutine XF_LT
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns true if the first value is less
# than the second value, ignoring case.

sub XF_LT
{
#	use locale ;
	return (lc $_[0] lt lc $_[1] ? 1 : 0) ;
}

# Subroutine XF_LT_NUM
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns true if the first value is less
# than the second value.

sub XF_LT_NUM
{
	return (0) if ($_[0] eq '' || $_[1] eq '') ;
	return ($_[0] < $_[1] ? 1 : 0) ;
}

# Subroutine XF_LE
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns true if the first value is less
# than or equal to the second value, ignoring case.

sub XF_LE
{
#	use locale ;
	return (lc $_[0] le lc $_[1] ? 1 : 0) ;
}

# Subroutine XF_LE_NUM
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns true if the first value is less
# than or equal to the second value.

sub XF_LE_NUM
{
	return ($_[0] eq $_[1] ? 1 : 0) if ($_[0] eq '' || $_[1] eq '') ;
	return ($_[0] <= $_[1] ? 1 : 0) ;
}

# Subroutine XF_GT
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns true if the first value is
# greater than the second value, ignoring case.

sub XF_GT
{
#	use locale ;
	return (lc $_[0] gt lc $_[1] ? 1 : 0) ;
}

# Subroutine XF_GT_NUM
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns true if the first value is
# greater than the second value.

sub XF_GT_NUM
{
	return (0) if ($_[0] eq '' || $_[1] eq '') ;
	return ($_[0] > $_[1] ? 1 : 0) ;
}

# Subroutine XF_GE
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns true if the first value is
# greater than or equal to the second value, ignoring case.

sub XF_GE
{
#	use locale ;
	return (lc $_[0] ge lc $_[1] ? 1 : 0) ;
}

# Subroutine XF_GE_NUM
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns true if the first value is
# greater than or equal to the second value.

sub XF_GE_NUM
{
	return ($_[0] eq $_[1] ? 1 : 0) if ($_[0] eq '' || $_[1] eq '') ;
	return ($_[0] >= $_[1] ? 1 : 0) ;
}

# Subroutine XF_ENV
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the contents of the environment
# variable.

sub XF_ENV
{
	return &GetServerVariable ($_[0]) ;
}

# Subroutine XF_N2PAT
#
# This extension function may be used in expression in hidden fields
# in the survey. This function returns a sequence of 0s and 1s used for
# permuting lists.

sub XF_N2PAT
{
	my $i = 1 ;
	my $N = shift ;
	my $len = shift ;
	my @pat ;
	while ($i <= $len + 1)
	{
		push @pat, $N % $i ;
		$N = int ($N/$i) ;
		$i++ ;
	}
	return @pat ;
}

# Subroutine XF_PERMUTE
#
# This extension function may be used in expression in hidden fields
# in the survey. This function returns the nth permutation of the comma
# separated list.

sub XF_PERMUTE
{
	$_ = $_[1] ;
	my $cnt = tr/,/,/ ;
	my $fac = &XF_FACTORIAL ($cnt) ;
	my $nth = ($_[0] > $fac ? ($_[0] > 0 ? (($_[0] - 1) % $fac) + 1 : 1) : $_[0]) ;
	my @pat = &XF_N2PAT ($nth, $cnt - 1) ;
	my @src = split (/,/, $_[1]) ;
	my @perm ;
	push @perm, splice (@src, (pop @pat), 1) while @pat ;
	return join (',', @perm) ;
}

# Subroutine XF_FACTORIAL
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the factorial of the given
# number.

sub XF_FACTORIAL
{
	my $n = shift ;
	return &XF_FACTORIAL (10) if ($n > 10) ;
	return $n * &XF_FACTORIAL ($n - 1) if ($n > 1) ;
	return 1 ;
}

# Subroutine XF_ABS
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the absolute value of the
# argument, which is expected to be a number.

sub XF_ABS
{
	return $_[0] if ($_[0] eq '' || $_[0] >= 0) ;
	return 0 - $_[0] ;
}

# Subroutine XF_CEIL
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the smallest integer that is
# greater than or equal to the argument, which is expected to be a
# number.

sub XF_CEIL
{
	return $_[0] if ($_[0] eq '' || int ($_[0]) == $_[0]) ;
	return int ($_[0] + 1) if ($_[0] >= 0) ;
	return int ($_[0]) ;
}

# Subroutine XF_CONTAINS_RE
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns true if the regular expression
# is contained in the string. Otherwise, returns false.

sub XF_CONTAINS_RE
{
	my $s = $_[0] ;
	my $re = $_[1] ;
	return $s =~ /$re/ ;
}

# Subroutine XF_CONTAINS
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns true if the pattern is contained
# in the string. Otherwise, returns false.

sub XF_CONTAINS
{
	my $s = $_[0] ;
	my $pat = quotemeta $_[1] ;
	return $s =~ /$pat/i ;
}

# Subroutine XF_DIV
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the result of dividing the
# second number into the first.

sub XF_DIV
{
	my $n = ($#_ >= 0 ? $_[0] : '') ;
	my $d = ($#_ >= 1 ? $_[1] : '') ;
	return '' if ($n eq '' || $d eq '' || $d == 0) ;
	return ($n / $d) ;
}

# Subroutine XF_EQ
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns true if the first value is equal
# to the second value, ignoring case.

sub XF_EQ
{
	return (lc $_[0] eq lc $_[1] ? 1 : 0) ;
}

# Subroutine XF_EQ_NUM
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns true if the first value is equal
# to the second value.

sub XF_EQ_NUM
{
	return ($_[0] eq $_[1] ? 1 : 0) if ($_[0] eq '' || $_[1] eq '') ;
	return ($_[0] == $_[1] ? 1 : 0) ;
}

# Subroutine XF_FLOOR
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the largest integer that is
# less than or equal to the argument, which is expected to be a
# number.

sub XF_FLOOR
{
	return $_[0] if ($_[0] eq '' || int ($_[0]) == $_[0]) ;
	return int ($_[0]) if ($_[0] >= 0) ;
	return int ($_[0] - 1) ;
}

# Subroutine XF_FORMAT_LOCALTIME
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns a formatted string version of
# the current time, given the specified date and time format numbers.
#
#  1 = yyyy/MM/dd
#	2 = yyyy/MM
#	3 = MM/dd/yy
#	4 = MM/dd/yyyy
#  5 = dd/MM/yy
#  6 = dd/MM/yyyy
#
#  1 = HH:mm
#  2 = hh:mm tt
#  3 = HH:mm:ss
#  4 = hh:mm:ss tt

sub XF_FORMAT_LOCALTIME
{
	my $df = ($#_ >= 0 ? $_[0] : 1) ;
	my $tf = ($#_ >= 1 ? $_[1] : 0) ;
	my $ds = '' ;
	my $ts = '' ;
	my $r = '' ;

	@_=(localtime());
	my $yyyy = ($_[5]+1900) ;
	my $yy = ((($yyyy%100)<10?'0':'').($yyyy%100)) ;
	my $MM = ($_[4]<9?'0':'').($_[4]+1) ;
	my $dd = ($_[3]<10?'0':'').($_[3]) ;
	my $HH = ($_[2]<10?'0':'').($_[2]) ;
	my $hh = ($_[2]==0?'12':($_[2]>12?($_[2]-12):$_[2])) ; $hh = ($hh<10?'0':'').($hh) ;
	my $mm = ($_[1]<10?'0':'').($_[1]) ;
	my $ss = ($_[0]<10?'0':'').($_[0]) ;
	my $tt = ($_[2]>=12?'PM':'AM') ;

	if ($df < 0 || $df > 6) { $df = 0 ; }
	if ($tf < 0 || $tf > 4) { $tf = 0 ; }

	if ($df == 1)		{ $ds = $yyyy.'/'.$MM.'/'.$dd ; }
	elsif ($df == 2)	{ $ds = $yyyy.'/'.$MM ; }
	elsif ($df == 3)	{ $ds = $MM.'/'.$dd.'/'.$yy ; }
	elsif ($df == 4)	{ $ds = $MM.'/'.$dd.'/'.$yyyy ; }
	elsif ($df == 5)	{ $ds = $dd.'/'.$MM.'/'.$yy ; }
	elsif ($df == 6)	{ $ds = $dd.'/'.$MM.'/'.$yyyy ; }

	if ($tf == 1)		{ $ts = $HH.':'.$mm ; }
	elsif ($tf == 2)	{ $ts = $hh.':'.$mm.' '.$tt ; }
	elsif ($tf == 3)	{ $ts = $HH.':'.$mm.':'.$ss ; }
	elsif ($tf == 4)	{ $ts = $hh.':'.$mm.':'.$ss.' '.$tt ; }

	if ($ds ne '' && $ts ne '')	{ $r = $ds.' '.$ts ; }
	elsif ($ds ne '')					{ $r = $ds ; }
	else									{ $r = $ts ; }

	return $r ;
}

# Subroutine XF_FORMAT_TIME
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns a formatted string version of
# the given time, given the specified date and time format numbers.
#
#  1 = yyyy/MM/dd
#	2 = yyyy/MM
#	3 = MM/dd/yy
#	4 = MM/dd/yyyy
#  5 = dd/MM/yy
#  6 = dd/MM/yyyy
#
#  1 = HH:mm
#  2 = hh:mm tt
#  3 = HH:mm:ss
#  4 = hh:mm:ss tt

sub XF_FORMAT_TIME
{
	my $df = ($#_ >= 0 ? $_[0] : 1) ;
	my $tf = ($#_ >= 1 ? $_[1] : 0) ;
	my $yp = ($#_ >= 2 ? $_[2] : 0) ;
	my $mp = ($#_ >= 3 ? $_[3] : 1) ;
	my $dp = ($#_ >= 4 ? $_[4] : 1) ;
	my $hp = ($#_ >= 5 ? $_[5] : 0) ;
	my $np = ($#_ >= 6 ? $_[6] : 0) ;
	my $sp = ($#_ >= 7 ? $_[7] : 0) ;
	my $ds = '' ;
	my $ts = '' ;
	my $r = '' ;

	my $yyyy = ($yp<10?'000':($yp<100?'00':($yp<1000?'0':''))).$yp ;
	my $yy = ((($yp%100)<10?'0':'').($yp%100)) ;
	my $MM = ($mp<10?'0':'').($mp) ;
	my $dd = ($dp<10?'0':'').($dp) ;
	my $HH = ($hp<10?'0':'').($hp) ;
	my $hh = ($hp==0?'12':($hp>12?($hp-12):$hp)) ; $hh = ($hh<10?'0':'').($hh) ;
	my $mm = ($np<10?'0':'').($np) ;
	my $ss = ($sp<10?'0':'').($sp) ;
	my $tt = ($hp>=12?'PM':'AM') ;

	if ($df < 0 || $df > 6) { $df = 0 ; }
	if ($tf < 0 || $tf > 4) { $tf = 0 ; }

	if ($df == 1)		{ $ds = $yyyy.'/'.$MM.'/'.$dd ; }
	elsif ($df == 2)	{ $ds = $yyyy.'/'.$MM ; }
	elsif ($df == 3)	{ $ds = $MM.'/'.$dd.'/'.$yy ; }
	elsif ($df == 4)	{ $ds = $MM.'/'.$dd.'/'.$yyyy ; }
	elsif ($df == 5)	{ $ds = $dd.'/'.$MM.'/'.$yy ; }
	elsif ($df == 6)	{ $ds = $dd.'/'.$MM.'/'.$yyyy ; }

	if ($tf == 1)		{ $ts = $HH.':'.$mm ; }
	elsif ($tf == 2)	{ $ts = $hh.':'.$mm.' '.$tt ; }
	elsif ($tf == 3)	{ $ts = $HH.':'.$mm.':'.$ss ; }
	elsif ($tf == 4)	{ $ts = $hh.':'.$mm.':'.$ss.' '.$tt ; }

	if ($ds ne '' && $ts ne '')	{ $r = $ds.' '.$ts ; }
	elsif ($ds ne '')					{ $r = $ds ; }
	else									{ $r = $ts ; }

	return $r ;
}

# Subroutine XF_INDEX_RE
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the one-based offset of the
# first occurrence of the regular expression in the string. If the
# regular expression is not found in the string, returns 0.

sub XF_INDEX_RE
{
	my $s = $_[0] ;
	my $re = $_[1] ;
	return $-[0] + 1 if ($s =~ /$re/g) ;
	return 0 ;
}

# Subroutine XF_INDEX
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the one-based offset of the
# first occurrence of the pattern in the string. If the pattern is not
# found in the string, returns 0.

sub XF_INDEX
{
	my $s = $_[0] ;
	my $p = $_[1] ;
	return index ($s, $p, 0) + 1 ;
}

# Subroutine XF_IS_FALSE_OR_NV
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns true if the passed in value is
# false or empty.

sub XF_IS_FALSE_OR_NV
{
	return !$_[0] || $_[0] eq '' ;
}

# Subroutine XF_IS_MISSING
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns true if the passed in value is
# empty.

sub XF_IS_MISSING
{
	return $_[0] eq '' ;
}

# Subroutine XF_IS_TRUE_NOT_NV
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns true if the passed in value is
# true.

sub XF_IS_TRUE_NOT_NV
{
	return $_[0] && $_[0] ne '' ;
}

# Subroutine XF_IS_TRUE_OR_NV
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns true if the passed in value is
# true or empty.

sub XF_IS_TRUE_OR_NV
{
	return $_[0] || $_[0] eq '' ;
}

# Subroutine XF_IS_VALID
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns true if the passed in value is
# not empty.

sub XF_IS_VALID
{
	return $_[0] ne '' ;
}

# Subroutine XF_LEFT
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the leftmost N characters from
# the first argument, which is expected to be a string.

sub XF_LEFT
{
	my $s = $_[0] ;
	my $n = $_[1] ;
	$n = length ($s) if ($n < 0 || $n > length ($s)) ;

	return substr ($s, 0, $n) ;
}

# Subroutine XF_LENGTH
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the number of characters used by
# the first argument, which is expected to be a string.

sub XF_LENGTH
{
	return length ($_[0]) ;
}

# Subroutine XF_LIST_CONTAINS
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns 1 if all of the elements in the
# first list are contained in the second list. The first argument is
# the list of elements to find. The second argument is the list to
# search. The third argument is an optional list of separators. The
# comma character is assumed to be the only list separator if the third
# argument is ommitted.

sub XF_LIST_CONTAINS
{
	my $l1 = ($#_ >= 0 ? $_[0] : '') ;
	my $l2 = ($#_ >= 1 ? $_[1] : '') ;
	my $s = ($#_ >= 2 ? $_[2] : ',') ;
	my @r1 = split (/[$s]/, $l1, length ($l1) + 1) ;
	my @r2 = split (/[$s]/, $l2, length ($l2) + 1) ;
	my $c = 0 ;
	if ($#r1 >= 0 && $#r2 >= 0)
	{
		# Remove extra spaces before and after
		{
			my $k = 0 ;
			for ($k = 0; $k <= $#r1; $k++) { $r1[$k] = XF_STRIP ($r1[$k]) ; }
			for ($k = 0; $k <= $#r2; $k++) { $r2[$k] = XF_STRIP ($r2[$k]) ; }
		}
		my $i = 0 ;
		for ($i = 0; $i <= $#r1; $i++)
		{
			my $j = 0 ;
			for ($j = 0; $j <= $#r2; $j++)
			{
				last if (XF_EQ ($r1[$i], $r2[$j])) ;	# Break if the element is found
			}
			last if ($j > $#r2) ;							# Break if the element was not found
		}
		$c = 1 if ($i > $#r1) ;								# All elements were found
	}
	return $c ;
}

# Subroutine XF_LIST_ELEMENT
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the nth element in the list. The
# first argument is the list, the second, the element number and the
# third, an optional list of separators. The comma character is assumed
# to be the only list separator if the third argument is ommitted.

sub XF_LIST_ELEMENT
{
	my $l = ($#_ >= 0 ? $_[0] : '') ;
	my $n = ($#_ >= 1 ? $_[1] : 0) ;
	my $s = ($#_ >= 2 ? $_[2] : ',') ;
	my @r = split (/[$s]/, $l, length ($l) + 1) ;
	return $n > 0 && $n - 1 <= $#r ? $r[$n - 1] : '' ;
}

# Subroutine XF_LIST_INDEX
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns location of the given element in
# the list. The first argument is the element to find, the second is
# the list and the third, an optional list of separators. The comma
# character is assumed to be the only list separator if the third
# argument is ommitted.

sub XF_LIST_INDEX
{
	my $f = XF_STRIP ($#_ >= 0 ? $_[0] : '') ;
	my $l = ($#_ >= 1 ? $_[1] : 0) ;
	my $s = ($#_ >= 2 ? $_[2] : ',') ;
	my @r = split (/[$s]/, $l, length ($l) + 1) ;
	my $i = -1 ;
	if ($#r >= 0)
	{
		for ($i = 0; $i <= $#r; $i++)
		{
			last if (XF_EQ (XF_STRIP ($r[$i]), $f)) ;		# Break if the element is found
		}
	}
	return $i >= 0 && $i <= $#r ? $i + 1 : 0 ;
}

# Subroutine XF_LIST_RANDOMIZE
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns a randomized version of the
# given list. The first argument is the list, the second is an optional
# list of elements to randomize, and the third is an optional list of
# separators. The entire list is randomized if the second argument is
# ommitted. The comma character is assumed to be the only list
# separator if the third argument is ommitted.

sub XF_LIST_RANDOMIZE
{
	my $l = ($#_ >= 0 ? $_[0] : '') ;
	my $f = ($#_ >= 1 ? $_[1] : '') ;
	my $s = ($#_ >= 2 ? $_[2] : ',') ;
	return ListReorder ($l, $f, $s, \&ArrayShuffle) ;
}

# Subroutine XF_LIST_REMOVE
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the result of removing all
# elements in the first list from the second. The first argument is the
# list of elements to remove. The second argument is the list from
# which to remove the elements. The third argument is an optional list
# of separators. The comma character is assumed to be the only list
# separator if the third argument is ommitted.

sub XF_LIST_REMOVE
{
	my $l1 = ($#_ >= 0 ? $_[0] : '') ;
	my $l2 = ($#_ >= 1 ? $_[1] : '') ;
	my $s = ($#_ >= 2 ? $_[2] : ',') ;
	my @r1 = split (/[$s]/, $l1, length ($l1) + 1) ;
	my @r2 = split (/[$s]/, $l2, length ($l2) + 1) ;
	if ($#r1 >= 0 && $#r2 >= 0)
	{
		# Remove extra spaces before and after
		{
			my $k = 0 ;
			for ($k = 0; $k <= $#r1; $k++) { $r1[$k] = XF_STRIP ($r1[$k]) ; }
			for ($k = 0; $k <= $#r2; $k++) { $r2[$k] = XF_STRIP ($r2[$k]) ; }
		}
		for (my $i = 0; $i <= $#r1; $i++)
		{
			for (my $j = $#r2; $j >= 0; $j--)
			{
				splice (@r2, $j, 1) if (XF_EQ ($r1[$i], $r2[$j])) ;	# Remove the element if it is found
			}
		}
	}
	return $#r2 >= 0 ? join (substr ($s, 0, 1), @r2) : '' ;
}

# Subroutine XF_LIST_REVERSE
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns a reversed version of the
# given list. The first argument is the list, the second is an optional
# list of elements to reverse, and the third is an optional list of
# separators. The entire list is reversed if the second argument is
# ommitted. The comma character is assumed to be the only list
# separator if the third argument is ommitted.

sub XF_LIST_REVERSE
{
	my $l = ($#_ >= 0 ? $_[0] : '') ;
	my $f = ($#_ >= 1 ? $_[1] : '') ;
	my $s = ($#_ >= 2 ? $_[2] : ',') ;
	return ListReorder ($l, $f, $s, \&ArrayReverse) ;
}

# Subroutine XF_LIST_ROTATE
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns a rotated version of the
# given list. The first argument is the list. The second is the
# rotation number. The third is an optional list of elements to rotate.
# The fourth is an optional list of separators. The entire list is
# rotated if the third argument is omitted. The comma character is
# assumed to be the only list separator if the fourth argument is
# ommitted.

sub XF_LIST_ROTATE
{
	my $l = ($#_ >= 0 ? $_[0] : '') ;
	my $n = ($#_ >= 1 ? $_[1] : 0) ;
	my $f = ($#_ >= 2 ? $_[2] : '') ;
	my $s = ($#_ >= 3 ? $_[3] : ',') ;
	return ListReorder ($l, $f, $s, \&ArrayRotate, $n) ;
}

# Subroutine XF_LIST_SIZE
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the number of elements in the
# given list. The first argument is the list, the second is an optional
# list of separators. The comma character is assumed to be the only
# list separator if the second argument is ommitted.

sub XF_LIST_SIZE
{
	my $l = ($#_ >= 0 ? $_[0] : 0) ;
	my $a = ($#_ >= 1 ? $_[1] : 1) ;
	my $s = ($#_ >= 2 ? $_[2] : ',') ;
	my @r = split (/[$s]/, $l, length ($l) + 1) ;
	if ($a == 0 && $#r > 0)
	{
		for (my $k = 0; $k <= $#r; $k++) { $r[$k] = XF_STRIP ($r[$k]) ; }
		for (my $i = 0; $i <= $#r - 1; $i++)
		{
			for (my $j = $#r; $j > $i; $j--)
			{
				splice (@r, $j, 1) if (XF_EQ ($r[$i], $r[$j])) ;	# Remove the element if it is found
			}
		}
	}
	return $#r >= 0 ? $#r + 1 : 0;
}

# Subroutine XF_LIT_TO_QTY
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the numeric version of the first
# argument, which is expected to be a string.

sub XF_LIT_TO_QTY
{
	return $_[0] ;
}

# Subroutine XF_LOCALTIME_PART
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns a number that corresponds to the
# specified element of the current time where 0=year, 1=month, 2=day,
# 3=hour, 4=minute, 5=second and 6=dayofweek.

sub XF_LOCALTIME_PART
{
	my $pf = ($#_ >= 0 ? $_[0] : 0) ;
	my $r = 0 ;

	@_=(localtime());
	if ($pf < 0 || $pf > 6) { $pf = 0 ; }

	if ($pf == 0)		{ $r = ($_[5] + 1900) ; }
	elsif ($pf == 1)	{ $r = ($_[4] + 1) ; }
	elsif ($pf == 2)	{ $r = $_[3] ; }
	elsif ($pf == 3)	{ $r = $_[2] ; }
	elsif ($pf == 4)	{ $r = $_[1] ; }
	elsif ($pf == 5)	{ $r = $_[0] ; }
	elsif ($pf == 6)	{ $r = $_[6] ; }

	return $r ;
}

# Subroutine XF_MAX
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the maximum value in a quantity
# variable. The expression must use the %recValue associative array to
# test the values of each record.

sub XF_MAX
{
	my $expr1 = $_[0] ;
	my $expr2 = ($#_ >= 1 ? $_[1] : 1) ;
	my $path = $E_dataFileName ;
	my $nResult = 0 ;

	if ($path ne '')
	{
		# Does the file exist?
		if (&CheckPathExists ($path) eq 'true')
		{
			# Wait for a shared lock
			local ($lockHandle, $lockPath, $lockMode) = &LockFile ($path, 1);

			# Open the data file for reading
			local $fileHandle = &OpenDataFileReadOnly ($path) ;

			# Read the first record (list of variable names)
			my $recData = &ReadDataFileRecord ($fileHandle) ;
			if ($recData ne '')
			{
				# Load the list of variable names into an array
				local (@vlst) = split (/,/, $recData) ;

				# Extract referenced variables from the expression
				my $exprs = $expr1 . '|' . $expr2 ;
				my $pattern = 'V_[a-zA-Z_0-9\$#]*' ;
				my (@vars) = ($exprs =~ m/$pattern/gi) ;
				my (%vpos) = MakeVPOS (@vars) ;
				my $bNoMax = 1 ;

				while ($recData ne '')
				{
					# Read the next record
					$recData = &ReadDataFileRecord ($fileHandle) ;
					if ($recData ne '')
					{
						# Split into an associative array of the referenced variables' values
						local (%recValue) = &RecordToValuesList ($recData, \%vpos) ;

						# Evaluate the expression
						# The expression can use the %recValue associate array
						my $bMatch = &SafeEval ($expr2) ;
						if ($@)
						{
							&DieMsg ("Fatal Error", "Error in expression \"" . &HTMLEncodeText ($expr2) . "\": " . $@, "Please contact this site's webmaster.") ;
						}
						elsif ($bMatch)
						{
							# Keep track of the maximum
							my $nValue = &SafeEval ($expr1) ;
							if ($@)
							{
								&DieMsg ("Fatal Error", "Error in expression \"" . &HTMLEncodeText ($expr1) . "\": " . $@, "Please contact this site's webmaster.") ;
							}
							elsif ($nValue > $nResult || $bNoMax)
							{
								$nResult = $nValue ;
								$bNoMax = 0 ;
							}
						}
					}
				}
			}

			# Close the data file			
			close ($fileHandle) ;

			# Release the shared lock			
			&UnlockFile ($lockHandle, $lockPath, $lockMode) ;
		}
	}
	return $nResult ;
}

# Subroutine XF_MEAN
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the arithmetic mean of a
# quantity variable. The expression must use the %recValue associative
# array to test the values of each record.

sub XF_MEAN
{
	my $expr1 = $_[0] ;
	my $expr2 = ($#_ >= 1 ? $_[1] : 1) ;
	my $path = $E_dataFileName ;
	my $nResult = 0 ;

	if ($path ne '')
	{
		# Does the file exist?
		if (&CheckPathExists ($path) eq 'true')
		{
			# Wait for a shared lock
			local ($lockHandle, $lockPath, $lockMode) = &LockFile ($path, 1);

			# Open the data file for reading
			local $fileHandle = &OpenDataFileReadOnly ($path) ;

			# Read the first record (list of variable names)
			my $recData = &ReadDataFileRecord ($fileHandle) ;
			if ($recData ne '')
			{
				# Load the list of variable names into an array
				local (@vlst) = split (/,/, $recData) ;

				# Extract referenced variables from the expression
				my $exprs = $expr1 . '|' . $expr2 ;
				my $pattern = 'V_[a-zA-Z_0-9\$#]*' ;
				my (@vars) = ($exprs =~ m/$pattern/gi) ;
				my (%vpos) = MakeVPOS (@vars) ;
				my $nSum = 0 ;
				my $nCnt = 0 ;

				while ($recData ne '')
				{
					# Read the next record
					$recData = &ReadDataFileRecord ($fileHandle) ;
					if ($recData ne '')
					{
						# Split into an associative array of the referenced variables' values
						local (%recValue) = &RecordToValuesList ($recData, \%vpos) ;

						# Evaluate the expression
						# The expression can use the %recValue associate array
						my $bMatch = &SafeEval ($expr2) ;
						if ($@)
						{
							&DieMsg ("Fatal Error", "Error in expression \"" . &HTMLEncodeText ($expr2) . "\": " . $@, "Please contact this site's webmaster.") ;
						}
						elsif ($bMatch)
						{
							# Keep track of the sum and count
							my $nValue = &SafeEval ($expr1) ;
							if ($@)
							{
								&DieMsg ("Fatal Error", "Error in expression \"" . &HTMLEncodeText ($expr1) . "\": " . $@, "Please contact this site's webmaster.") ;
							}
							else
							{
								$nSum += $nValue ;
								$nCnt++ ;
							}
						}
					}
				}
				# Calculate the arithmetic mean
				$nResult = $nSum / $nCnt if ($nCnt > 0) ;
			}

			# Close the data file			
			close ($fileHandle) ;

			# Release the shared lock			
			&UnlockFile ($lockHandle, $lockPath, $lockMode) ;
		}
	}
	return $nResult ;
}

# Subroutine XF_MIDSTR
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the specified number of
# characters from the first argument. The second argument is the
# starting character position (1=first character) and the third
# argument, which is optional, is the number of characters to return.

sub XF_MIDSTR
{
	my $s = $_[0] ;
	my $f = $_[1] ;

	return '' if ($f < 0 || $f > length ($s)) ;
			
	$f = $f - 1 if ($f > 0) ;

	my $n = ($#_ >= 2 ? $_[2] : length ($s) - $f);
	$n = length ($s) - $f if ($n > length ($s) - $f) ;

	return substr ($s, $f, $n);
}

# Subroutine XF_MIN
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the minimum value in a quantity
# variable. The expression must use the %recValue associative array to
# test the values of each record.

sub XF_MIN
{
	my $expr1 = $_[0] ;
	my $expr2 = ($#_ >= 1 ? $_[1] : 1) ;
	my $path = $E_dataFileName ;
	my $nResult = 0 ;

	if ($path ne '')
	{
		# Does the file exist?
		if (&CheckPathExists ($path) eq 'true')
		{
			# Wait for a shared lock
			local ($lockHandle, $lockPath, $lockMode) = &LockFile ($path, 1);

			# Open the data file for reading
			local $fileHandle = &OpenDataFileReadOnly ($path) ;

			# Read the first record (list of variable names)
			my $recData = &ReadDataFileRecord ($fileHandle) ;
			if ($recData ne '')
			{
				# Load the list of variable names into an array
				local (@vlst) = split (/,/, $recData) ;

				# Extract referenced variables from the expression
				my $exprs = $expr1 . '|' . $expr2 ;
				my $pattern = 'V_[a-zA-Z_0-9\$#]*' ;
				my (@vars) = ($exprs =~ m/$pattern/gi) ;
				my (%vpos) = MakeVPOS (@vars) ;
				my $bNoMin = 1 ;

				while ($recData ne '')
				{
					# Read the next record
					$recData = &ReadDataFileRecord ($fileHandle) ;
					if ($recData ne '')
					{
						# Split into an associative array of the referenced variables' values
						local (%recValue) = &RecordToValuesList ($recData, \%vpos) ;

						# Evaluate the expression
						# The expression can use the %recValue associate array
						my $bMatch = &SafeEval ($expr2) ;
						if ($@)
						{
							&DieMsg ("Fatal Error", "Error in expression \"" . &HTMLEncodeText ($expr2) . "\": " . $@, "Please contact this site's webmaster.") ;
						}
						elsif ($bMatch)
						{
							# Keep track of the minimum
							my $nValue = &SafeEval ($expr1) ;
							if ($@)
							{
								&DieMsg ("Fatal Error", "Error in expression \"" . &HTMLEncodeText ($expr1) . "\": " . $@, "Please contact this site's webmaster.") ;
							}
							elsif ($nValue < $nResult || $bNoMin)
							{
								$nResult = $nValue ;
								$bNoMin = 0 ;
							}
						}
					}
				}
			}

			# Close the data file			
			close ($fileHandle) ;

			# Release the shared lock			
			&UnlockFile ($lockHandle, $lockPath, $lockMode) ;
		}
	}
	return $nResult ;
}

# Subroutine XF_MODULO
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the remainder from dividing the
# second number into the first.

sub XF_MODULO
{
	my $n = ($#_ >= 0 ? $_[0] : '') ;
	my $d = ($#_ >= 1 ? $_[1] : '') ;
	return '' if ($n eq '' || $d eq '' || $d == 0) ;
	return ($n % $d) ;
}

# Subroutine XF_NE
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns true if the first value is not
# equal to the second value, ignoring case.

sub XF_NE
{
	return (lc $_[0] ne lc $_[1] ? 1 : 0) ;
}

# Subroutine XF_NE_NUM
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns true if the first value is not
# equal to the second value.

sub XF_NE_NUM
{
	return ($_[0] ne $_[1] ? 1 : 0) if ($_[0] eq '' || $_[1] eq '') ;
	return ($_[0] != $_[1] ? 1 : 0) ;
}

# Subroutine XF_NEG
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the negative version of the
# first argument, which is expected to be a number.

sub XF_NEG
{
	return 0 - $_[0] ;
}

# Subroutine XF_NOT
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the opposite of the first
# argument, which is expected to be true or false.

sub XF_NOT
{
	return !$_[0] ;
}

# Subroutine XF_PERCENTAGE
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the percenage of respondents
# meeting a condition. The expression must use the %recValue
# associative array to test the values of each record.

sub XF_PERCENTAGE
{
	my (@para) = @_ ;
	return &XF_RATIO (@para) * 100 ;
}

# Subroutine XF_POWER
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the the first argument raised by
# the second argument. Both arguments are expected to be numbers.

sub XF_POWER
{
	return $_[0] ** $_[1] ;
}

# Subroutine XF_QTY_TO_LIT
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the literal version of the first
# argument, which is expected to be a number.

sub XF_QTY_TO_LIT
{
	return $_[0] ;
}

# Subroutine XF_RAND
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns a random number between 0 and
# the argument, which is expected to be a number.

sub XF_RAND
{
	my $n1 = ($#_ >= 0 ? $_[0] : 1) ;
	return '' if ($n1 eq '') ;
	return $n1 * rand ;
}

# Subroutine XF_RATIO
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the proportion of respondents
# meeting a condition. The expression must use the %recValue
# associative array to test the values of each record.

sub XF_RATIO
{
	my $expr1 = $_[0] ;
	my $expr2 = ($#_ >= 1 ? $_[1] : 1) ;
	my $path = $E_dataFileName ;
	my $nResult = 0 ;

	if ($path ne '')
	{
		# Does the file exist?
		if (&CheckPathExists ($path) eq 'true')
		{
			# Wait for a shared lock
			local ($lockHandle, $lockPath, $lockMode) = &LockFile ($path, 1);

			# Open the data file for reading
			local $fileHandle = &OpenDataFileReadOnly ($path) ;

			# Read the first record (list of variable names)
			my $recData = &ReadDataFileRecord ($fileHandle) ;
			if ($recData ne '')
			{
				# Load the list of variable names into an array
				local (@vlst) = split (/,/, $recData) ;

				# Extract referenced variables from the expression
				my $exprs = $expr1 . '|' . $expr2 ;
				my $pattern = 'V_[a-zA-Z_0-9\$#]*' ;
				my (@vars) = ($exprs =~ m/$pattern/gi) ;
				my (%vpos) = MakeVPOS (@vars) ;
				my $nCnt1 = 0 ;
				my $nCnt2 = 0 ;

				while ($recData ne '')
				{
					# Read the next record
					$recData = &ReadDataFileRecord ($fileHandle) ;
					if ($recData ne '')
					{
						# Split into an associative array of the referenced variables' values
						local (%recValue) = &RecordToValuesList ($recData, \%vpos) ;

						# Evaluate the 2nd expression
						# The expression can use the %recValue associate array
						my $bMatch2 = &SafeEval ($expr2) ;
						if ($@)
						{
							&DieMsg ("Fatal Error", "Error in expression \"" . &HTMLEncodeText ($expr2) . "\": " . $@, "Please contact this site's webmaster.") ;
						}
						elsif ($bMatch2)
						{
							$nCnt2++ ;

							# Evaluate the 1st expression
							# The expression can use the %recValue associate array
							my $bMatch1 = &SafeEval ($expr1) ;
							if ($@)
							{
								&DieMsg ("Fatal Error", "Error in expression \"" . &HTMLEncodeText ($expr1) . "\": " . $@, "Please contact this site's webmaster.") ;
							}
							elsif ($bMatch1)
							{
								$nCnt1++ ;
							}
						}
					}
				}
				# Calculate the proportion
				$nResult = $nCnt1 / $nCnt2 if ($nCnt2 > 0) ;
			}

			# Close the data file			
			close ($fileHandle) ;

			# Release the shared lock			
			&UnlockFile ($lockHandle, $lockPath, $lockMode) ;
		}
	}
	return $nResult ;
}

# Subroutine XF_REPLACE_RE
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function replaces all occurrences of the regular
# expression in the string with the replacement value.

sub XF_REPLACE_RE
{
	my $s = $_[0] ;
	my $re = $_[1] ;
	my $r = $_[2] ;
	$s =~ s/$re/$r/g ;
	return $s ;
}

# Subroutine XF_REPLACE
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function replaces all occurrences of the pattern
# in the string with the replacement value.

sub XF_REPLACE
{
	my $s = $_[0] ;
	my $pat = quotemeta $_[1] ;
	my $r = $_[2] ;
	$s =~ s/$pat/$r/gi ;
	return $s ;
}

# Subroutine XF_RIGHT
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the rightmost N characters from
# the first argument, which is expected to be a string.

sub XF_RIGHT
{
	my $s = $_[0] ;
	my $n = $_[1] ;
	$n = length ($s) if ($n < 0 || $n > length ($s)) ;

	return substr ($s, 0 - $n, $n);
}

# Subroutine XF_ROUND
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the argument rounded using the
# given precision. The arguments are expected to be numbers.

sub XF_ROUND
{
	my $n1 = ($#_ >= 0 ? $_[0] : '') ;
	my $p1 = ($#_ >= 1 ? $_[1] : 0) ;

	return '' if ($n1 eq '' || $p1 eq '') ;
	if ($p1 > 0)
	{
		my $r = 10 ** ($p1 > 10 ? 10 : $p1) ;
		return int (($n1 * $r) + 0.5) / $r if ($n1 >= 0) ;
		return int (($n1 * $r) - 0.5) / $r ;
	}
	return int ($n1 + 0.5) if ($n1 >= 0) ;
	return int ($n1 - 0.5) ;
}

# Subroutine XF_STRIP
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the string with spaces removed
# from the beginning and the end.

sub XF_STRIP
{
	my $s = $_[0] ;
	$s =~ s/^\s+|\s+$//g ;
	return $s ;
}

# Subroutine XF_SUBSTR_RE
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the first part in the string
# that matches the regular expression.

sub XF_SUBSTR_RE
{
	my $s = $_[0] ;
	my $re = $_[1] ;
	$s =~ /($re)/ ;
	return $1 ;
}

# Subroutine XF_SUBSTR
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the first part in the string
# that matches the pattern.

sub XF_SUBSTR
{
	my $s = $_[0] ;
	my $pat = quotemeta $_[1] ;
	$s =~ /($pat)/i ;
	return $1 ;
}

# Subroutine XF_TOLOWER
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the first argument as a string,
# replacing all upper-case letters with lower-case letters.

sub XF_TOLOWER
{
	return lc $_[0] ;
}

# Subroutine XF_TOUPPER
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the first argument as a string,
# replacing all lower-case letters with upper-case letters.

sub XF_TOUPPER
{
	return uc $_[0] ;
}

# Subroutine XF_WEBSERVER_ENV
#
# This extension function may be used in expressions in hidden fields
# in the survey. This function returns the contents of the environment
# variable.

sub XF_WEBSERVER_ENV
{
	return &GetServerVariable ($_[0]) ;
}

# ------------------------------
# Platform dependent subroutines
# ------------------------------

# --- CGI ---

# Subroutine GetServerVariable
#
#

sub GetServerVariable
{
	return $ENV{$_[0]} ;
}

# Subroutine GetQueryString
#
#

sub GetQueryString
{
	return $ENV{'QUERY_STRING'} ;
}

# Subroutine GetFormData
#
#

sub GetFormData
{
	local ($len) = $_[0] ;
	local ($errflag) = '' ;
	local ($got) = read (STDIN, $raw_input, $len) ;
	
	if ($got != $len)
	{
		$errflag = "Short Read: wanted $len, got $got\n";
	}
	return $errflag ;
}

# Subroutine GetContentTypeHTML
#
#

sub GetContentTypeHTML
{
	return "Content-Type: text/html\n\n" ;
}

# Subroutine SendToOutput
#
#

sub SendToOutput
{
	print $_[0] ;
}

# Subroutine GetLocationRedirect
#
#

sub GetLocationRedirect
{
	return "Location: ".$_[0]."\n\n" ;
}
