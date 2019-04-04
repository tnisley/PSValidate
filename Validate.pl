# ValidatePSFiles
# Author: Trystan Nisley
# Company: The Papers Inc.
# Description: This program address a problem in the Auto & RV 
#  workflow where grayscale images sometimes create issues when
#  the postscript file is created. This program detects bad postscript
#  files and places good and bad files in separate folders.

#!/usr/bin/perl
use strict;
use warnings;
use File::Copy;
use Time::Piece;
use autodie;
##########################################
#                  MAIN                  #
##########################################
my $ROOTFOLDER = ".";		   
my $PSFOLDER = "PS Files";
my $GOODFOLDER = "Validated";
my $BADFOLDER = "Bad_Files";
my $LOGFILE = "$ROOTFOLDER/validate.log";

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
		
		if ($isValid == -1)
		{
			moveFileToFolder($fP, $badFolder);
			logBadFile($rawFile);
		}
		elsif ($isValid == 1)
		{
			moveFileToFolder($fP, $goodFolder);
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
	opendir($dh, $ROOTFOLDER);
	my @directories = readdir($dh);
	closedir ($dh);
	my @subDirs;
	foreach my $dir (@directories)
	{
		my $filePath = "$dir/$PSFOLDER";
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