# ValidatePSFiles
# Author: Trystan Nisley
# Company: The Papers Inc.
# Description: This program address a problem in the Auto & RV 
#  workflow where grayscale images sometimes create issues when
#  the postscript file is created. This program detects bad postscript
#  files and places good and bad files in separate folders.

# Version 2.0: Consolidates print and web workflow. Now when a file is 
# validated, a copy is automatically sent to the E-Advance Folder 
# to be processed for the web. When running, there is no need to have
# AdSpeed export a PS file to the web E-Advance folder.



#!/usr/bin/perl
use strict;
use warnings;
use File::Copy;
use Time::Piece;
use autodie;
##########################################
#                  MAIN                  #
##########################################
my $OUTPUTFILES = "./Output Files";		
my $EADVANCEFOLDER = "./E-Advance";   
my $PSFOLDER = "PS Files";
my $GOODFOLDER = "Validated";
my $BADFOLDER = "Bad_Files";
my $LOGFILE = "./validate.log";

my @PSFoldersToCheck = getPSFoldersToCheck(); 
foreach my $folder (@PSFoldersToCheck)
{
	
	checkGoodBadFolders($folder);
	my $goodFolder = "$folder/$GOODFOLDER";  #set where processed files go.
	my $badFolder = "$folder/$BADFOLDER";

	my @notValidated = getPSFilesFromFolder($folder);
	
	foreach my $rawFile (@notValidated)
	{
		my $fP = "$folder/$rawFile";          # create full file path
		my $isValid = validateFile("$fP");
		
		if ($isValid == -1) # Validation failed
		{
			move($fP, $badFolder);   #move file to bad folder
			logBadFile($rawFile);
		}
		elsif ($isValid == 1) # Validation success
		{
			# Place copy in E-Advance
			my $eFolder = GetEFolder($fP);
			if ($eFolder ne "")
			{
				my $eAdvance = "$EADVANCEFOLDER/$eFolder/In";
				copy($fP, $eAdvance);
			}
			
			#move file to bad folder
			move($fP, $goodFolder);  
		}
	}
}

####################################################

# Checks for folders with PS files needing checked.
# Returns list of subdirecotries containing PS files.
# Assumes directory structure ./book/PSFOLDER.

sub getPSFoldersToCheck
{
	my $dh;
	opendir($dh, $OUTPUTFILES);
	my @directories = readdir($dh);
	closedir ($dh);
	my @subDirs;
	foreach my $dir (@directories)
	{
		my $filePath = "$OUTPUTFILES/$dir/$PSFOLDER";
		if (-d "$filePath")
		{
			push @subDirs,"$filePath";
		}
	}
	return @subDirs;
}


# Checks that bad and good folders exist in given file folder.
# If not, it creates them.
# Parameter - Folder to check.
sub checkGoodBadFolders
{ 
	my ($folder) = @_;
	my $goodFolder ="$folder/$GOODFOLDER"; 
	my $badFolder ="$folder/$BADFOLDER"; 
	
	mkdir $goodFolder unless -d $goodFolder;
	mkdir $badFolder unless -d $badFolder;
}


# Returns list of PS files from a given folder.
# Parameter - File to check.
sub getPSFilesFromFolder
{
	my ($folder) = @_;
	my $dh;
	opendir($dh, $folder);
	my @PSFiles = grep(/\.ps$/,readdir($dh));
	closedir($dh);
	return @PSFiles;
}


# validateFile uses $TEXTOFIND to see if the postscript file
# is good. Returns 1 if good, -1 if bad. Returns 0 on error.
# Uses a file path as a parameter. 
sub validateFile
{
	my ($fileToValidate) = @_;
	my $TEXTTOFIND = "InDesignDefaultInsertProc"; # Presence of this text indicates bad file
	no autodie qw(open);
	if (open(my $fh, $fileToValidate))
	{
		while (my $line = <$fh>)
		{
			if (index($line, $TEXTTOFIND) != -1) #if text is found
			{

				close $fh or die "Lost connection to server.";
				return -1;  # File not valid
			}
		}
		close $fh;
		return 1;
	}
	else
	{
		return 0;
	}
}


# Move file to a specified folder
# Parameters - (file to move, destination)
sub moveFileToFolder
{
	my ($source, $destination) = @_;
	move($source, $destination);
	
	
}

# Logs bad file name with date for record keeping purpses.
# Takes name of file as parameter.
sub logBadFile
{
	my ($fileName) = @_;
	my $date = localtime;
	no autodie qw(open);
	if (open(my $fh, '>>', $LOGFILE))
	{
		print $fh $date->ymd, ":  $fileName\n";
		close $fh;
	}
}

# Parse the state from the file path 
# and return the name of E-Advance folder
sub GetEFolder
{
	my ($filename) = @_;
	
	if (index($filename, "IL A") != -1)
	{
		return "IL";
	}
	elsif (index($filename, "IN A") != -1)
	{
		return "INA";
	}
	elsif (index($filename, "IN B") != -1)
	{
		return "INB";
	}
	elsif (index($filename, "KA A") != -1)
	{
		return "KA";
	}
	elsif (index($filename, "MI A") != -1)
	{
		return "MIA";
	}
	elsif (index($filename, "OHE A") != -1)
	{
		return "OHE";
	}
	elsif (index($filename, "OHW A") != -1)
	{
		return "OHW";
	}
	elsif (index($filename, "WI A") != -1)
	{
		return "WI";
	}
	elsif (index($filename, "WD N") != -1)
	{
		return "NA";
	}
	
	#Testing Purposes
	elsif (index($filename, "TEST") != -1)
	{
		return "TEST";
	}
	
	else     # cant parse folder
	{ 
		return "";
	}	
}