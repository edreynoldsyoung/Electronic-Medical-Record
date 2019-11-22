#!/usr/bin/perl -w

use strict 'vars';
use warnings;
use DBI;
use CGI::Pretty qw(:standard :html3 );
package main;

my $cgi= new CGI;
my %ALL_FIELDS=();
my $dbh='';
my $dbh2='';
my $dbase = 'DBI:mysql:emr';
my %PAGES = (
			 1=>'Login',
			 2=>'Main Screen',
			 3=>'Patient File',
			 4=>'Demographics',
			 5=>'Update Record',
			 6=>'New Encounter',
	                 7=>'Reports',
	                 8=>'Referrals',
	                 9=>'Letters'
#	     9=>'Closing Patient File',
#	     10=>'Logout'
			 );

my %patient =('id'=>['ID',20,'','##'],
	      'title'=>['Title',20,'',['--','Mr','Mrs','Ms','MD','PhD','Esq']],
	      'fname'=>['First Name',20,'','--'],
	      'mname'=>['Middle Name',20,'','--'],
	      'lname'=>['Last Name',20,'','--'],
	      'DOB'=>['Date of Birth',20,'','-YYYY-MM-DD'],

	      'street'=>['Street',20,'','--------'],
	      'postal_code'=>['Postal Code',20,'','#####-####'],
	      'city'=>['City',20,'','New York'],
	      'state'=>['State',20,'','NY'],
	      'country_code'=>['Country Code',20,'','United States'],

	      'ss'=>['Social Security Number',20,'','###-##-####'],
	      'occupation'=>['Occupation',20,'','--'],
	      'phone_home'=>['Home Phone',20,'','###-###-####'],
	      'phone_biz'=>['Buisness Phone',20,'','###-###-####'],
	      'phone_contact'=>['Phone Contact',20,'','###-###-#####'],
	      'phone_cell'=>['Cell Phone',20,'','###-###-####'],
	      'status'=>['Status',20,'','--'],
	      'contact_relationship'=>['Contact Relationship',20,'','--'],
	      'date'=>['Date',20,'','-YYYY-MM-DD'],
	      'sex'=>['Sex',20,'',['--','M','F']],
	      'language'=>['Language',20,'',['--','English','Spanish','French','Chinese']],
	      'financial'=>['Financial',20,'','--'],
	      'referrer'=>['Referrer',20,'','--'],
	      'referrerID'=>['Referrer ID',20,'','##'],
	      'provider_id'=>['Provider',20,'','##'],
	      'email'=>['email',20,'','------@----.---'],
	      'ethnoracial'=>['Ethnoracial',20,'',['--','White','Hispacnic','Afro-American','Asian','Amer-Indian','South-Asian']],
	      'interpretter'=>['Interpretter',20,'','--'],
	      'migrantseasonal'=>['Seasonal Migrant',20,'',['--','Yes','No']],
	      'family_size'=>['Family Size',20,'','##'],
	      'monthly_income'=>['Monthly Income',20,'','##'],
	      'homeless'=>['Homeless',20,'','--'],
	      'financial_review'=>['Financial Review',20,'','-YYYY-MM-DD'],
	      'pubpid'=>['pubpid',20,'','##'],
	      'pid'=>['Patient ID',20,'','##'],
	      'genericname1'=>['Generic Name 1',20,'','--'],
	      'genericval1'=>['Generic val 1',20,'','--'],
	      'genericname2'=>['Generic Name 2',20,'','--'],
	      'genericval2'=>['Generic val 2',20,'','--'],
	      'hipaa_mail'=>['HIPPA Mail',3,'NO',['--','YES','NO']],
	      'hipaa_voice'=>['HIPPA Voice',3,'NO',['--','YES','NO']],
	      'healthcare_proxy'=>['Healthcare Proxy',20,'','--------'],
	      'phone_pharmacy'=>['Pharmacy Phone',20,'','###-###-####'],
	      'allergies'=>['Allergies',100,'','---------']
	     );

################################################################################
##  Main Control of flow Section

my ($page_directory, $page_content, $print_page, $page_name, $found_patient, $pid, $JSCRIPT);

############  Assign Page Name
if (param) {
  if (param('PageButton')){
    $page_name = param('PageButton');
  } elsif (param('SubmitButton')){
    $page_name = submit_page(param('SubmitButton'), param('page'));
  }
} else {
  $page_name = 'Login';
}

if (param){

  ############  Connect to Database
  my %attr = (
	      PrintError => 1,
	      RaiseError => 1
	     );
  $dbh = DBI->connect(
		      $dbase,
		      param('User'),
		      param('Password'),
		      \%attr
		     ) or die(print $cgi->header(), "Error connecting to Database");

  unless(($page_name eq 'Print Note') || ($page_name eq 'Print Letter') || (param('SubmitButton') eq 'Print') || (param('SubmitButton') eq 'Print Front Sheet')){
    $page_content .= qq!<div class="content">!;
  }

  ##### Main Screen
  if ($page_name eq "Main Screen") {
    $page_content .= Main_Screen();
  }

  #####  Patient File
  elsif ($page_name eq 'Patient File'){
    $page_content .= Patient_File(param('patient_id') || param('SubmitButton'));
  } 

  ##### Demographics
  elsif ($page_name eq 'Demographics'){
    $page_content .= Patient_Demographics(param('patient_id'));
  } 

  ##### Update Record
  elsif ($page_name eq 'Update Record'){
    $page_content .= Update_Record(param('patient_id'));
  } 

  ##### New Encounter
  elsif ($page_name eq 'New Encounter'){
    $page_content .= New_Encounter(param('patient_id'));
  } 

  #####  Reports
  elsif ($page_name eq 'Reports'){
    $page_content .= Reports(param('patient_id'));
  } 

  #####  Referrals
  elsif ($page_name eq 'Referrals'){
    $page_content .= Referrals(param('patient_id'));
  }

  #####  Letters
  elsif ($page_name eq 'Letters'){
    $page_content .= Letters(param('patient_id'));
  }

  #####  Print Letters
  elsif ($page_name eq 'Print Letter'){
    $page_content .= Print_Letter(param('patient_id'), param('SubmitButton'));
  }

  #### Print Note
  elsif ($page_name eq 'Print Note'){
    $page_content .= Print_Note(param('SubmitButton'), param('patient_id'));
  }
  unless(($page_name eq 'Print Note') || (param('SubmitButton') eq 'Print') || (param('SubmitButton') eq 'Print Front Sheet')){
    $page_content .= Hidden_Fields(param('patient_id'));
  }
  $dbh->disconnect;
}
else {
  $page_content .= print_login();
}

############  Print Top of Page
$print_page  = header();
$print_page .= qq|
<?xml version="1.0" standalone="yes" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Trasition//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>OpenEmr</title>
<link rev="made" href="mailto:eyoung%40chpnet.org" />
<link rel="stylesheet" type="text/css" href="http://localhost/style1.css" />
<script type="text/javascript" src='http://localhost/javascripts/script1.js'></script>|;
#<script type="text/javascript" src='http://localhost/javascripts/utils.js'></script>
#<script type="text/javascript" src='http://localhost/javascripts/calendar.js'></script>
#<script type="text/javascript" src='http://localhost/javascripts/calendar-en.js'></script>
#<script type="text/javascript" src='http://localhost/javascripts/calendar-setup.js'></script>
$print_page .= qq|</head>
<body>
|;
unless(($page_name eq 'Print Note') || ($page_name eq 'Print Letter') || (param('SubmitButton') eq 'Print') || (param('SubmitButton') eq 'Print Front Sheet')){
  $print_page .= start_multipart_form(-name=>'form1');
  $print_page .= print_header();
}
if (param('SubmitButton') eq 'Print Front Sheet'){
  $print_page .= qq!<div class="FrontSheet">!;
}
unless(($page_name eq 'Print Note') || ($page_name eq 'Print Letter') || (param('SubmitButton') eq 'Print') || (param('SubmitButton') eq 'Print Front Sheet')){
  $print_page .= Directory(param('patient_id'));
}
$print_page .= $page_content;
unless(($page_name eq 'Print Note') || ($page_name eq 'Print Letter') || (param('SubmitButton') eq 'Print') || (param('SubmitButton') eq 'Print Front Sheet')){
  $print_page .= qq!</div>!;
  $print_page .= $cgi -> end_form();
}
if (param('SubmitButton') eq 'Print Front Sheet'){
  $print_page .= qq!</div>!;
}
$print_page .= qq!</body></html>!;
print $print_page;

################################################################################
## Given: Name of submit button and current page.
## Return: Appropriate  name of new page180

sub submit_page {
  my ($submit_button, $current_page) = @_;
  my $submit_page;
  if ($submit_button eq 'Login'){$submit_page = 'Main Screen';}
  if ($current_page eq 'Main Screen'){
    if ($submit_button eq 'Add'){$submit_page = 'Main Screen';}
    if ($submit_button eq 'Find'){$submit_page = 'Main Screen';}
    if ($submit_button =~ /\d+/){$submit_page = 'Patient File';}
  }
  if ($current_page eq 'Patient File'){
    if ($submit_button eq 'Demographics'){$submit_page = 'Demographics';}
    if ($submit_button eq 'New Encounter'){$submit_page = 'New Encounter';}
    if ($submit_button =~ /\d+/){$submit_page = 'Print Note';}
    if ($submit_button eq 'Print Front Sheet'){$submit_page = 'Patient File';}
  }
  if ($current_page eq 'Demographics'){
    if ($submit_button eq 'Update'){$submit_page = 'Demographics';}
  }
  if ($current_page eq 'Update Record'){
    if ($submit_button eq 'Choose This Problem'){$submit_page = 'Update Record';}
    if ($submit_button eq 'Add New Problem'){$submit_page = 'Update Record';}
    if ($submit_button eq 'Search for Problem'){$submit_page = 'Update Record';}
    if ($submit_button eq 'Select Problems'){$submit_page = 'Update Record';}
    if ($submit_button eq 'Change Medication'){$submit_page = 'Update Record';}
    if ($submit_button eq 'Find Medication'){$submit_page = 'Update Record';}
    if ($submit_button eq 'Pick Medication'){$submit_page = 'Update Record';}
    if ($submit_button eq 'Pick Strength'){$submit_page = 'Update Record';}
    if ($submit_button eq 'Pick Route'){$submit_page = 'Update Record';}
    if ($submit_button eq 'Pick Frequency'){$submit_page = 'Update Record';}
    if ($submit_button eq 'Pick Package'){$submit_page = 'Update Record';}
    if ($submit_button eq 'Add Medication'){$submit_page = 'Update Record';}
    if ($submit_button eq 'Stop Medication'){$submit_page = 'Update Record';}
    if ($submit_button eq 'Update'){$submit_page = 'Update Record';}	
  }
  if ($current_page eq 'New Encounter'){
    if ($submit_button eq 'Choose This Problem'){$submit_page = 'New Encounter';}
    if ($submit_button eq 'Add New Problem'){$submit_page = 'New Encounter';}
    if ($submit_button eq 'Search for Problem'){$submit_page = 'New Encounter';}
    if ($submit_button eq 'Select Problems'){$submit_page = 'New Encounter';}
    if ($submit_button eq 'Change Medication'){$submit_page = 'New Encounter';}
    if ($submit_button eq 'Find Medication'){$submit_page = 'New Encounter';}
    if ($submit_button eq 'Pick Medication'){$submit_page = 'New Encounter';}
    if ($submit_button eq 'Pick Strength'){$submit_page = 'New Encounter';}
    if ($submit_button eq 'Pick Route'){$submit_page = 'New Encounter';}
    if ($submit_button eq 'Pick Package'){$submit_page = 'New Encounter';}
    if ($submit_button eq 'Add Medication'){$submit_page = 'New Encounter';}
    if ($submit_button eq 'Stop Medication'){$submit_page = 'New Encounter';}
    if ($submit_button eq 'Order Test'){$submit_page = 'New Encounter';}
    if ($submit_button eq 'Pick Observation Class Type'){$submit_page = 'New Encounter';}
    if ($submit_button eq 'Pick Observation Class'){$submit_page = 'New Encounter';}
    if ($submit_button eq 'Pick Observation'){$submit_page = 'New Encounter';}
    if ($submit_button eq 'Pick Method'){$submit_page = 'New Encounter';}
    if ($submit_button eq 'Pick System'){$submit_page = 'New Encounter';}
    if ($submit_button eq 'Full Review of Systems'){$submit_page ='New Encounter';}
    if ($submit_button eq 'Past/Social/Family History'){$submit_page='New Encounter';}
    if ($submit_button eq 'Assessment and Plan'){$submit_page='New Encounter';}
    if ($submit_button eq 'Print'){$submit_page = 'New Encounter';}
  }
  if ($current_page eq 'New Medication'){
    if ($submit_button eq 'Pick Strength'){$submit_page = 'New Medication';} 
  }
  if ($current_page eq 'Reports'){
    if ($submit_button eq 'Graphs'){$submit_page='Reports';}
    if ($submit_button eq 'Missed Mammo'){$submit_page='Reports';}
    if ($submit_button eq 'No Mammo'){$submit_page='Reports';}
    if ($submit_button eq 'Missed Colonoscopy'){$submit_page='Reports';}
    if ($submit_button eq 'No Colonoscopy'){$submit_page='Reports';}
    if ($submit_button eq 'Missed HgbA1c'){$submit_page='Reports';}
    if ($submit_button eq 'All Diabetics'){$submit_page='Reports';}
    if ($submit_button eq 'Diabetes Report'){$submit_page='Reports';}
  }
  if ($current_page eq 'Referrals'){
    if ($submit_button eq 'Add'){$submit_page='Referrals';}
    if ($submit_button eq 'Find'){$submit_page='Referrals';}
    if ($submit_button eq 'Add Referral'){$submit_page='Referrals';}
  }
  if ($current_page eq 'Letters'){
    if ($submit_button eq 'Work Letter'){$submit_page='Letters';}
    if ($submit_button eq 'Lab Notification'){$submit_page='Letters';}
    if ($submit_button eq 'Patient Discharge'){$submit_page='Letters';}
    if ($submit_button eq 'Physician Discharge'){$submit_page='Letters';}
    if ($submit_button eq 'Transfer Records'){$submit_page='Letters';}
    if ($submit_button eq 'Blank Letter'){$submit_page='Letters';}
    if ($submit_button eq 'Print'){$submit_page='Letters';}
    if ($submit_button =~/\d+/){$submit_page='Print Letter';}
  }
  return($submit_page);
}

################################################################################
## Given: name of current page
## Returns: Appropriate header

sub print_header {
  my $print_header;
  
  $print_header = qq!<div class="header">!;
  $print_header .= qq!<span class="UMPA">UMPA Faculty Practice</span>
    <span class="user">Logged in as !.param('User').qq!</span>
 		      <span class="page">$page_name</span>
		      <span class="time">!.(scalar localtime(time())).qq!</span>!;
  $print_header .= "</div>";
  return ($print_header);
}

################################################################################
## Login Screen

sub print_login {
  my $print_login;
  $cgi->delete_all();
  $print_login = qq!<div class="content">!;
  $print_login .= qq!
<table>
<tr><td><fieldset><legend>User</legend><input type='text' name='User' size=50></fieldset></td></tr>	
<tr><td><fieldset><legend>Password</legend><input type='password' name='Password' size=50></td></tr>
<tr><td><input type='submit' name='SubmitButton' value='Login'></td></tr>
</table>
!;
  $print_login .= Hidden_Fields();
  $print_login .= qq!</div>!;
  return($print_login);
}

################################################################################
## Returns a set of submit buttons to header

sub Directory {
  my $patient_id = shift;
  my $directory = qq!<div class="banner">!;
  my ($sql, $sth, $ref, $encounterdates, $letterdates);
  my @previous_notes;

  #######################################################  Pages
  $directory .= qq!Pages!;
  $directory .= qq!
<input type='submit' name='PageButton' value="Main Screen" class="submit">
<input type='submit' name='PageButton' value="Login" class="submit">
<input type='submit' name='PageButton' value="Referrals" class="submit">
<input type='submit' name='PageButton' value="Reports" class="submit">
!;
  if ($patient_id ||($page_name eq 'Patient File' && param('SubmitButton'))){
    $directory .= qq!
<input type='submit' name='PageButton' value="Patient File" class="submit">
<input type='submit' name='PageButton' value="Demographics" class="submit">
<input type='submit' name='PageButton' value="Update Record" class="submit">
<input type='submit' name='PageButton' value="New Encounter" class="submit">
<input type='submit' name='PageButton' value="Letters" class="submit">
!;
  }
  $directory .= qq!<hr>!;

  ####################################################### Actions
  $directory .= qq!Actions!;

  #####  Main Screen
  if ($page_name eq 'Main Screen'){
    if (param('SubmitButton') eq "Find"){
      $directory .= qq!<br>Choose ID!;
      $directory .= find_patient(param('find_patient_by_pid'),
				 param('find_patient_by_fname'),
				 param('find_patient_by_lname'),
				 param('find_patient_by_phone'),
				 param('find_patient_by_DOB'),
				 param('find_patient_by_gender'),
				 'directory'
				);
    } else {
      $directory .= qq!
<input type='submit' name='SubmitButton' value='Find' class="submit">
<input type='submit' name='SubmitButton' value='Add' class="submit">
!;
    }
  }

  #####  Patient File
  if ($page_name eq 'Patient File'){
    $directory .= qq!<input type='submit' name='SubmitButton' value='Print Front Sheet' class='submit'>!;

    ##### Get Dates of old notes

    $sql = qq!SELECT date 
FROM pnotes 
WHERE  pid = '!;
    if ($patient_id){
      $sql .= $patient_id;
    }
    if (param('SubmitButton')=~/^\d*/){
      $sql .= param('SubmitButton');
    }
    $sql .= qq!' ORDER by date DESC;!;
    $sth           = $dbh->prepare($sql);
    $sth              ->execute;
    while ($ref       = $sth->fetch){
      $encounterdates = @$ref[0];
      $encounterdates =~ s/(\d+)-(\d+)-(\d+)/$2-$3-$1/;
      push(@previous_notes, qq!<input type='submit' name='SubmitButton' value="$encounterdates" class="submit">!);
    }

    unshift (@previous_notes, qq!<input type='submit' name='SubmitButton' value='New Encounter' class="submit">!);
  }
  foreach (@previous_notes){
    $directory .= qq!$_!;
  }

  #####  Demographics
  if ($page_name eq 'Demographics'){
    $directory .= $cgi-> submit(-name=>'SubmitButton', -value=>'Update', -class=>"submit");
  }

  ##### Update Record
  if ($page_name eq 'Update Record'){
    $directory .= qq!<input type="submit" name="SubmitButton" value="Update" class="submit">!;
    unless (param("Drug_Name_Search") || param('Medication_Frequency') || param('Medication_Name') || param('Medication_Strength') || param('Medication_Route') || (param('SubmitButton') eq 'Change Medication') || param('SubmitButton') eq 'Stop Medication'){
      $directory .= qq!
<input type="submit" Name="SubmitButton" Value="Find Medication" class="submit" onClick="shiftFocus('FindMedication')">
<input type="submit" name="SubmitButton" value="Change Medication" class="submit" onClick="shiftFocus('ChangeMedication')">
<input type="submit" name="SubmitButton" value="Stop Medication" class="submit">
!;
    } elsif (param("Drug_Name_Search")) {
      $directory .= qq!<input type="submit" name="SubmitButton" value='Pick Medication' class="submit" onClick="shiftFocus('PickMedication')">!;
    } elsif (param("Medication_Name")){
      $directory .= qq!<input type="submit" name="SubmitButton" value='Pick Strength' class="submit" onClick="shiftFocus('PickStrength')">!;
    } elsif (param("Medication_Strength")){
      $directory .= qq!<input type="submit" name="SubmitButton" value='Pick Route' class="submit" onClick="shiftFocus('PickRoute')">!;
    } elsif (param("Medication_Route")){
      $directory .= qq!<input type="submit" name="SubmitButton" value='Pick Frequency' class="submit" onClick="shiftFocus('PickFrequency')">!;
    } elsif (param("Medication_Frequency")){
      $directory .= qq!<input type="submit" name="SubmitButton" value='Pick Package' class="submit" onClick="shiftFocus('PickPackage')">!;
    } elsif(param('SubmitButton') eq 'Change Medication') {
      $directory .= qq!<input type="submit" name="SubmitButton" value="Change Medication" class="submit">!;
    }
    if (param('SubmitButton') eq 'Add New Problem'){
      $directory .= qq!<input type="submit" name="SubmitButton" value="Search for Problem" class="submit">!;
    }
    elsif (param('SubmitButton') eq 'Search for Problem'){
      $directory .= qq!<input type="submit" name="SubmitButton" value="Choose This Problem" class="submit">!;
    } else {
      $directory .= qq!<input type="submit" name="SubmitButton" value="Add New Problem" class="submit">!;
    }
  }

  ##### New Encounter
  if ($page_name eq 'New Encounter'){
    if (param('Todays_Problems')){
       $directory .= qq!<input type="submit" name="SubmitButton" value="Assessment and Plan" class="submit">!;
    }
    elsif (param('SubmitButton') eq "Assessment and Plan"){
      $directory .= qq!
<input type="submit" name="SubmitButton" value="Change Medication" class="submit">
<input type="submit" name="SubmitButton" value="Stop Medication" class="submit">
<input type="submit" name="SubmitButton" value="Add Medication" class="submit" on >
<input type="submit" name="SubmitButton" value="Print" class="submit">!;
    }
    else {
      if (param('SubmitButton') eq 'Add New Problem'){
	$directory .= qq!<input type="submit" name="SubmitButton" value="Search for Problem" class="submit">!;
      }
      elsif (param('SubmitButton') eq 'Search for Problem'){
	$directory .= qq!<input type="submit" name="SubmitButton" value="Choose This Problem" class="submit">!;
      } else {
	$directory .= qq!
<input type="submit" name="SubmitButton" value="Add New Problem" class="submit">
<input type="submit" name="SubmitButton" value="Select Problems" class="submit">
!;
      }
    }
  }

  #####  Referrals
  if($page_name eq 'Referrals'){
    $directory .= qq!
<input type='submit' name='SubmitButton' value='Find' class="submit">
<input type='submit' name='SubmitButton' value='Add' class="submit">
!;
    if (param('SubmitButton') eq 'Find'){
      $directory .= qq!Choose ID!;
      $directory .= Find_Referral('directory');
    }
  }

  #####  Letters
  if($page_name eq 'Letters'){

    if ((param('SubmitButton') eq 'Work Letter') || (param('SubmitButton') eq 'Lab Notification') || (param('SubmitButton') eq 'Patient Discharge') || (param('SubmitButton') eq 'Transfer Records') || (param('SubmitButton') eq 'Blank Letter')){
      $directory .= qq!
<input type='submit' name='SubmitButton' value='Print' class='submit'>
!;
    } else {
      $directory .= qq!
<input type='submit' name='SubmitButton' value='Work Letter' class="submit">
<input type='submit' name='SubmitButton' value='Lab Notification' class="submit">
<input type='submit' name='SubmitButton' value='Patient Discharge' class="submit">
<input type='submit' name='SubmitButton' value='Physician Discharge' class="submit">
<input type='submit' name='SubmitButton' value='Transfer Records' class="submit">
<input type='submit' name='SubmitButton' value='Blank Letter' class="submit">
!;
      $directory .= qq!<hr>!;
    $sql = qq!SELECT date 
FROM letters 
WHERE  patient_id = $patient_id 
ORDER by date DESC!;
    $sth           = $dbh->prepare($sql);
    $sth              ->execute;
    while ($ref       = $sth->fetch){
      $letterdates = @$ref[0];
      $letterdates =~ s/(\d+)-(\d+)-(\d+)/$2-$3-$1/;
      push(@previous_notes, qq!<input type='submit' name='SubmitButton' value="$letterdates" class="submit">!);
    }

    $directory .= qq!Old Letters!;
      foreach (@previous_notes){
	$directory .= qq!$_!;
      }
      
    }
  }

  #####  Reports
  if ($page_name eq 'Reports'){
    $directory .= qq!
<input type='submit' name='SubmitButton' value='Graphs' class="submit">
<input type='submit' name='SubmitButton' value='Missed Mammo' class="submit">
<input type='submit' name='SubmitButton' value='No Mammo' class="submit">
<input type='submit' name='SubmitButton' value='Missed Colonoscopy' class="submit">
<input type='submit' name='SubmitButton' value='No Colonoscopy' class="submit">
<input type='submit' name='SubmitButton' value='Missed HgbA1c' class="submit">
<input type='submit' name='SubmitButton' value='All Diabetics' class="submit">
<input type='submit' name='SubmitButton' value='Diabetes Report' class="submit">
!;
  }
  $directory .= qq!</div>!;;
  return ($directory);
}

################################################################################
## 

sub find_patient {
  my ($pid, $fname, $lname, $phone_home, $dob, $gender, $from) = @_;
  my $main;
  my $sql="SELECT pid, fname, lname, phone_home, DOB, sex FROM patient_data WHERE ";
  if (($pid ne $patient{'pid'}[3]) && ($pid ne 'Patient ID')) {$sql.="pid = '$pid' AND ";}
  if (($fname ne $patient{'fname'}[3]) && ($fname ne 'First Name')) {$sql.="fname = '$fname' AND ";}
  if (($lname ne $patient{'lname'}[3]) && ($lname ne 'Last Name')){$sql.="lname = '$lname' AND ";}
  if (($phone_home ne $patient{'phone_home'}[3]) && ($phone_home ne 'Home Phone Number')) {$sql.="phone_home = '$phone_home' AND ";}
  if (($dob ne $patient{'DOB'}[3]) && ($dob ne 'Date of Birth')) {$sql.="DOB = '$dob' AND ";}
  if (($gender ne $patient{'sex'}[3][1]) && ($gender ne 'gender')) {$sql .= qq!sex = "$gender"!;}
  $sql =~ s/(.*)AND $/$1/;
  my $sth = $dbh->prepare($sql);
  $sth->execute or die("\nError executing SQL statement! $DBI::errstr");
  my ($pidreturn, $lnamereturn, $fnamereturn, $phone_homereturn, $dobreturn, $genderreturn);
  $sth->bind_columns(\$pidreturn, \$fnamereturn, \$lnamereturn, \$phone_homereturn, \$dobreturn, \$genderreturn);
  while($sth->fetch){
    if ($from eq 'directory'){
      $main .= qq!<input type='submit' name='SubmitButton' value="$pidreturn" class='submit'>!;
    }
    elsif ($from eq 'main'){
      $main .=qq!<tr><td>$pidreturn</td><td>$fnamereturn</td><td>$lnamereturn</td><td>$phone_homereturn</td><td>$dobreturn</td><td>$genderreturn</td></tr>!;
    }
  }

  return ($main);
}

################################################################################
##

sub add_patient_data {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday, $isdst) = localtime;
	$year =~ s/^(\d)/20/;
	$mon = $mon + 1;
	my $sql = "INSERT INTO patient_data (pid, lname, fname, DOB, phone_home, sex) VALUES ('".param('pid')."', '".param('lname')."', '".param('fname')."', '".param('DOB')."', '".param('phone_home')."', '".param('gender')."') ON DUPLICATE KEY UPDATE date='$year-$mon-$mday';";
	my $query = $dbh->prepare($sql);
	$query->execute or die("\nError executing SQL statement! $DBI::errstr");
	return ();
}

################################################################################
## Recieves name of database, table, field and any limitations.
## Returns ordered list of distinct values for a drop down menu.

sub Drop_Down_Item_List {
	my $dbh   = shift;
	my $table = shift;
	my $field = shift;
	my $limit = shift;
	my $default = shift;
	my $ref   = undef;
	my @list;
	my $sql   = "SELECT DISTINCT $field FROM $table ";
	if ($limit ne ''){
		$sql .= "Where $limit ";
	}
	$sql .=  "ORDER BY $field";
	my $sth     = $dbh->prepare($sql);
	$sth->execute;
	while ($ref = $sth->fetch) {
		push(@list, @$ref);
	}
	if ($default ne ''){
	  push (@list, $default);
	} elsif ($patient{$field}[3]){
	  push (@list,$patient{$field}[3]); # Adds the default value
	} else {push (@list, '  ')};
	return(@list);
}

################################################################################
##  Returns today's date in the form: YYYY-MM-DD (date format for MySQL)

sub todays_date {
	my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday, $isdst) = localtime;
	my $date;
	$year  =~ s/^(\d)/20/;
	$mon   = $mon + 1;
	$mday  = $mday;
	$date  = "$year-$mon-$mday";
	return $date;
}

################################################################################
##  Returns hidden fields on all of the FIELD

sub Hidden_Fields {
  my $patient_id = shift;
  my ($hidden_fields, $sql, $sth, $hidden_provider_id, $username, $password);
  unless ($page_name eq 'Login'){
    $sql="SELECT id, username, password from users where username='".param('User')."' AND password='".param('Password')."'";
    $sth=$dbh->prepare($sql);
    $sth->execute;
    $sth -> bind_columns(\($hidden_provider_id, $username, $password));
    $sth->fetch;
    $hidden_fields .= qq!<input type='hidden' name='hidden_provider_id' value="$hidden_provider_id" />!;
    $hidden_fields .= qq!<input type='hidden' name='User' value="$username" />!;
    $hidden_fields .= qq!<input type='hidden' name='Password' value="$password" />!;
    $hidden_fields .= qq!<input type='hidden' name='page' value="$page_name" />!;
    if ($patient_id && $page_name ne 'Main Screen'){
	$hidden_fields .= qq!<input type="hidden" name='patient_id' value='!.$patient_id.qq!'>!;
    }
    if ($page_name eq 'Patient File'){
      $hidden_fields .= qq!<input type='hidden' name='patient_id' value='!.param('SubmitButton').qq!'>!;
    }
    if (($page_name eq 'New Encounter') || ($page_name eq 'Update Record')){
      if (param('Type_of_Problem') == 3){$hidden_fields .= qq!<input type="hidden" name='Type_of_Problem' value='3'>!;}
      if (param('Type_of_Problem') == 2){$hidden_fields .= qq!<input type="hidden" name='Type_of_Problem' value='2'>!;}
      if (param('Type_of_Problem') == 1){$hidden_fields .= qq!<input type="hidden" name='Type_of_Problem' value='1'> !;}
      if (param('Type_of_Problem') == 0){$hidden_fields .= qq!<input type="hidden" name='Type_of_Problem' value='0'> !;}
      if ((param('SubmitButton') eq "New Encounter") || ((param('Pick Problem') eq "Yes") && (param('Todays_Problems') eq ''))){
	$hidden_fields .= qq!<input type="hidden" name="Pick Problem" value="Yes">!;
      }
      unless (param('Drug_Name_Completed') || param('Package')){
	if (param('Medication_Name')){
	  $hidden_fields .= qq!<input type="hidden" name='Hidden_Medication_Name' value='!.param('Medication_Name').qq!'>!;
	}
	if (param('Hidden_Medication_Name') && !param('Medication_Name')){
	  $hidden_fields .= qq!<input type="hidden" name='Hidden_Medication_Name' value='!.param('Hidden_Medication_Name').qq!'>!;
	}
	if (param('Medication_Strength')){
	  $hidden_fields .= qq!<input type="hidden" name='Hidden_Medication_Strength' value='!.param('Medication_Strength').qq!'>!;
	}
	if (param('Hidden_Medication_Strength') && !param('Medication_Strength')){
	  $hidden_fields .= qq!<input type="hidden" name='Hidden_Medication_Strength' value='!.param('Hidden_Medication_Strength').qq!'>!;
	}
	if (param('Medication_Note')){
	  $hidden_fields .= qq!<input type="hidden" name='Hidden_Medication_Note' value='!.param('Medication_Note').qq!'>!;
	}
	if (param('Hidden_Medication_Note') && !param('Medication_Note')){
	  $hidden_fields .= qq!<input type="hidden" name='Hidden_Medication_Note' value='!.param('Hidden_Medication_Note').qq!'>!;
	}
	if (param('Medication_Route')){
	  $hidden_fields .= qq!<input type="hidden" name='Hidden_Medication_Route' value='!.param('Medication_Route').qq!'>!;
	}
	if (param('Hidden_Medication_Route') && !param('Medication_Route')){
	  $hidden_fields .= qq!<input type="hidden" name='Hidden_Medication_Route' value='!.param('Hidden_Medication_Route').qq!'>!;
	}
	if (param('Medications') && !param('Medication_Name') && !param('Hidden_Medication_Name')){
	  $hidden_fields .= qq!<input type="hidden" name="Hidden_Medications" value='!.param('Medications').qq!'>!;
	}
	if (param('Hidden_Medications') && !param('Medications')){
	  $hidden_fields .= qq!<input type="hidden" name="Hidden_Medications" value='!.param('Hidden_Medications').qq!'>!;
	}
	if (param('Medication_Frequency')){
	  $hidden_fields .= qq!<input type="hidden" name="Hidden_Medication_Frequency" value='!.param('Medication_Frequency').qq!'>!;
	}
	if (param('Hidden_Medication_Frequency') && !param('Medication_Frequency')){
	  $hidden_fields .= qq!<input type="hidden" name="Hidden_Medication_Frequency" value='!.param('Hidden_Medication_Frequency').qq!'>!;
	}
	if (param('Medication_Package')){
	  $hidden_fields .= qq!<input type="hidden" name="Hidden_Package" value='!.param('Medication_Package').qq!'>!;
	}
	if (param('Hidden_Medication_Package') && !param('Medication_Package')){
	  $hidden_fields .= qq!<input type="hidden" name="Hidden_Package" value='!.param('Hidden_Medication_Package').qq!'>!;
	}
      }
    }

    ##### Letters
    if ($page_name eq 'Letters'){
      if (param('SubmitButton') eq 'Work Letter'){
	$hidden_fields .= qq!<input type="hidden" name="Hidden_Letter" value="Work Letter" >!;
      }
      if (param('SubmitButton') eq 'Lab Notification'){
	$hidden_fields .= qq!<input type="hidden" name="Hidden_Letter" value="Lab Notification" >!;
      }
      if (param('SubmitButton') eq 'Patient Discharge'){
	$hidden_fields .= qq!<input type="hidden" name="Hidden_Letter" value="Patient Discharge" >!;
      }
      if (param('SubmitButton') eq 'Physician Discharge'){
	$hidden_fields .= qq!<input type="hidden" name="Hidden_Letter" value="Physician Discharge" >!;
      }
      if (param('SubmitButton') eq 'Transfer Records'){
	$hidden_fields .= qq!<input type="hidden" name="Hidden_Letter" value="Transfer Records" >!;
      }
      if (param('SubmitButton') eq 'Blank Letter'){
	$hidden_fields .= qq!<input type="hidden" name="Hidden_Letter" value="Blank Letter" >!;
      }

    }
  }
  return ($hidden_fields);
}

################################################################################
## 'Main_Screen' page

sub Main_Screen {

  my ($Find_Patient_Data, $found_patient, $Add_Patient_Data, $main);

  if (param('SubmitButton') eq 'Add') {
    add_patient_data();
  }
  elsif (param('SubmitButton') eq 'Find'){
    $found_patient = find_patient(param('find_patient_by_pid'),
				  param('find_patient_by_fname'),
				  param('find_patient_by_lname'),
				  param('find_patient_by_phone'),
				  param('find_patient_by_DOB'),
				  param('find_patient_by_gender'),
				  'main'
				 );
  }

  ## Find Patient Data
  $Find_Patient_Data .= qq!<td>!.$cgi->popup_menu(-name=>'find_patient_by_pid',
						  -values=>[Drop_Down_Item_List($dbh, 'patient_data', 'pid', '', 'Patient ID')],
						  -default=>'Patient ID',
						  -onBlur=>"shiftFocus('find_patient')"
						     ).qq!</td>!;
  $Find_Patient_Data .= qq!<td>!.$cgi->popup_menu(-name=>'find_patient_by_fname',
						  -values=>[Drop_Down_Item_List($dbh, 'patient_data', 'fname', '', 'First Name')],
						  -default=>'First Name',
						  -onBlur=>"shiftFocus('find_patient')"
						 ).qq!</td>!;
  $Find_Patient_Data .= qq!<td>!.$cgi->popup_menu(-name=>'find_patient_by_lname',
						  -values=>[Drop_Down_Item_List($dbh, 'patient_data', 'lname', '', 'Last Name')],
						  -default=>'Last Name',
						  -onBlur=>"shiftFocus('find_patient')"
						 ).qq!</td>!;
  $Find_Patient_Data .= qq!<td>!.$cgi->popup_menu(-name=>'find_patient_by_phone',
						  -values=>[Drop_Down_Item_List($dbh, 'patient_data', 'phone_home', '', 'Home Phone Number')],
						  -default=>'Home Phone Number',
						  -onBlur=>"shiftFocus('find_patient')"
						 ).qq!</td>!;
  $Find_Patient_Data .= qq!<td>!.$cgi->popup_menu(-name=>'find_patient_by_DOB',
						  -values=>[Drop_Down_Item_List($dbh, 'patient_data', 'DOB', '', 'Date of Birth')],
						  -default=>'Date of Birth',
						  -onBlur=>"shiftFocus('find_patient')"
						 ).qq!</td>!;
  $Find_Patient_Data .= qq!<td><select name='find_patient_by_gender' onBlur="shiftFocus('find_patient')">
    <option value="gender">Gender</option><option value="M">Male</option><option value="F">Female</option></select></td>!;

  
  ### Add Patient Data
  $Add_Patient_Data .= qq!<td><input type='text' name='pid' /></td><td><input type='text' name='fname' /></td><td><input type='text' name='lname' /></td><td><input type='text' name='phone_home' /></td><td><input type='text' name='DOB' /></td><td><input type='text' name='gender'></td>!;
  
  ### Main Page Layout Table
  $main = qq!<table>
    <tr><th>Patient ID</th><th>First Name</th><th>Last Name</th><th>Home Phone Number</th><th>Date of Birth</th><td>Gender</td></tr>
    <tr>$Find_Patient_Data</tr>
    $found_patient
    <tr>$Add_Patient_Data</tr>
	    </table>!;
  return $main;
}

################################################################################
## 'Patient File' page

sub Patient_File {
  my $patient_id = shift;
  my ($sql, $ref, $page, $name, $identification, $contact_information, $additional, $extra, $problems, $medications, $prevention, $immunizations, $chroniccare, $counselling, $sexCancer, $concept, $code, $date_added, $active, $chronic);
  my(@meds, @started, @stopped, @modified, @filled, @expires, @row, @past, @chronic, @ongoing, @acute);
  
  if ($patient_id){
    ############################################  Patient Demographics
    $sql = qq!SELECT  title, language, fname, lname, mname, DOB, street, postal_code, city, state, country_code, ss, occupation, phone_home, phone_biz, phone_contact, phone_cell, status, contact_relationship, date, sex, referrer, provider_id, email, ethnoracial, interpretter, family_size, hipaa_mail, hipaa_voice , allergies, phone_pharmacy, healthcare_proxy
FROM patient_data 
WHERE pid = "$patient_id"!;
    my $sth = $dbh -> prepare($sql);
    $sth -> execute;
    my (
	$title, 
	$language, 
	$fname, 
	$lname,
	$mname,
	$DOB,
	$street,
	$postal_code,
	$city,
	$state,
	$country_code,
	$ss,
	$occupation,
	$phone_home,
	$phone_biz,
	$phone_contact,
	$phone_cell,
	$status,
	$contact_relationship,
	$date,
	$sex,
	$referrer,
	$provider_id,
	$email,
	$ethnoracial,
	$interpretter,
	$family_size,
	$hipaa_mail,
	$hipaa_voice,
	$allergies,
	$phone_pharmacy,
	$healthcare_proxy
       );
    $sth -> bind_columns(
			 \$title,
			 \$language,
			 \$fname,
			 \$lname,
			 \$mname,
			 \$DOB,
			 \$street,
			 \$postal_code,
			 \$city,
			 \$state,
			 \$country_code,
			 \$ss,
			 \$occupation,
			 \$phone_home,
			 \$phone_biz,
			 \$phone_contact,
			 \$phone_cell,
			 \$status,
			 \$contact_relationship,
			 \$date,
			 \$sex,
			 \$referrer,
			 \$provider_id,
			 \$email,
			 \$ethnoracial,
			 \$interpretter,
			 \$family_size,
			 \$hipaa_mail,
			 \$hipaa_voice,
			 \$allergies,
			 \$phone_pharmacy,
			 \$healthcare_proxy
			);
    while ($sth -> fetch){
      $DOB =~ s/(\d*)-(\d*)-(\d*)/$2\/$3\/$1/;
      $date  =~ s/(\d*)-(\d*)-(\d*)(.*)/$2\/$3\/$1/;
      $provider_id = (Drop_Down_Item_List($dbh, 'users', 'lname',"id = '".param(hidden_provider_id)."'"))[0];
      if ($title) {$name = $title." ";} $name = $fname." "; if ($mname){$name .= $mname." ";} $name .= $lname;
      $identification = qq!<table>
			<tr ><th><b>Date of Birth: </b></th><td>$DOB</td></tr>
                        <tr><th><b>UMPA ID: </b></th><td>$patient_id</td></tr>
			<tr ><th><b>Primary Physician: </b></th><td>$provider_id</td></tr>
			<tr ><th><b>Specialist: </b></th><td></td></tr>
		    </table>!;
      $contact_information = qq!<table>
			<tr><th><b>Address</b></th><td>$street</td></tr>
			<tr><th><b>City</b></th><td>$city</td></tr>
			<tr><th><b>State</b></th><td>$state</td></tr>
			<tr><th><b>Zip</b></th><td>$postal_code</td></tr>
			<tr><th><b>Country</b></th><td>$country_code</td></tr>
			<tr><th><b>Home Phone</b></th><td>$phone_home</td></tr>
			<tr><th><b>Business Phone</b></th><td>$phone_biz</td></tr>
			<tr><th><b>Cell Phone</b></th><td>$phone_cell</td></tr>
			<tr><th><b>Phone Conact</b></th><td>$phone_contact</td></tr>
			<tr><th><b>e-mail</b></th><td>$email</td></tr>
		    </table>!;
      $additional = qq!<table>
			<tr><th><b>Occupation</b></th><td>$occupation</td></tr>
			<tr><th><b>Language</b></th><td>$language</td></tr>
			<tr><th><b>Race/Ethnicity</b></th><td>$ethnoracial</td></tr>
			<tr><th><b>Gender</b></th><td>$sex</td></tr>
			<tr><th><b>Domestic Partner</b></th><td>$status</td></tr>
			<tr><th><b>Social Security Number</b></th><td>$ss</td></tr>
		  </table>!;
      $extra = qq!<table>
			<tr><th><b>Allergies: </b></th><td>$allergies</td></tr>
			<tr><th><b>Pharmacy Phone: </b></th><td>$phone_pharmacy</td></tr>
			<tr><th><b>Healthcare Proxy: </b></th><td>$healthcare_proxy</td></tr>
		  </table>!;
    }
    #####################################################################  Problem List
    $problems = qq!<table>
		<tr>
                  <th size='10%'></th><th size='60%'>Problem</th><th size='10%'>ICD.9</th><th size='10%'>Date of<BR>Onset</th><th size='10%'>Active</th>
		</tr>!;
    $sql   = "SELECT concept, code, date_added, active, chronic 
FROM problem_list LEFT JOIN icd_9_cm_concepts ON problem_list.problem_id=icd_9_cm_concepts.id 
WHERE patient_id='".$patient_id."'";
    $sth = $dbh->prepare($sql);
    $sth ->execute;
    $sth ->bind_columns(\($concept, $code, $date_added, $active, $chronic));
    while ($sth->fetch){
      $date_added  =~ s/(\d*)-(\d*)-(\d*)(.*)/$2\/$3\/$1/;
      $concept =~s/(.*)\[.*\]/$1/;
      if ($active == 1){$active = "Yes";}else{$active = "No";}
      if ($chronic == 3){
	push (@past, [$concept, $code, $date_added, $active]); 
      }
      if ($chronic == 2){
	push (@chronic, [$concept, $code, $date_added, $active]);
      }
      elsif ($chronic == 1){
	push (@ongoing, [$concept, $code, $date_added, $active]);
      }
      elsif ($chronic == 0){
	push (@acute, [$concept, $code, $date_added, $active]);
      }
    }
    my $index = 0;
    $problems .= qq!<tr><td>Past Problems</td><td></td><td></td><td></td></tr>!;
    for ($index = 0; $index<=$#past; $index++){
      $problems .= qq!<tr><td></td><td>$past[$index][0]</td><td>$past[$index][1]</td><td>$past[$index][2]</td><td>$past[$index][3]</td></tr>!;
    }
    $problems .= qq!<tr><td>Chronic Problems</td><td></td><td></td><td></td></tr>!;
    for ($index = 0; $index<=$#chronic; $index++){
      $problems .= qq!<tr><td></td><td>$chronic[$index][0]</td><td>$chronic[$index][1]</td><td>$chronic[$index][2]</td><td>$chronic[$index][3]</td></tr>!;
    }
    $problems .= qq!<tr><td>Ongoing Problems</td><td></td><td></td><td></td></tr>!;
    for ($index = 0; $index<=$#ongoing; $index++){
      $problems .= qq!<tr><td></td><td>$ongoing[$index][0]</td><td>$ongoing[$index][1]</td><td>$ongoing[$index][2]</td><td>$ongoing[$index][3]</td></tr>!;
    }
    $problems .= qq!<tr><td>Acute Problems</td><td></td><td></td><td></td></tr>!;
    for ($index = 0; $index<=$#acute; $index++){
      $problems .= qq!<tr><td></td><td>$acute[$index][0]</td><td>$acute[$index][1]</td><td>$acute[$index][2]</td><td>$acute[$index][3]</td></tr>!;
    }
    #  $problems .= qq!<input type='submit' name='SubmitButton' value='Add Medications'>!;
    #  if (param('SubmitButton' eq 'Add Medicdations'){Get_Medication
    $problems .= "</table>";
    
    
    ####################################################################  Medication List
    
    $medications = qq{<table>
	  <tr><td></td>
	  <th>Date Added</th>
	  <th>Date Modified</th>
	  <th>Date Stopped</th>
	  <th>Last Filled</th>
          <th>Refills</th>
	  <th>Expires</th></tr>
  };
    
    $sql = "SELECT drug, dosage, unit, route_name, frequency, date_added, date_modified, date_stopped, date_filled, refills, note, active  
FROM prescriptions LEFT JOIN tblroute ON prescriptions.route=tblroute.route_code 
WHERE patient_id = '".$patient_id."' ORDER BY active DESC";
    $sth = $dbh->prepare($sql);
    $sth->execute or die("\nError executing SQL statement! $DBI::errstr");
    while  ($ref = $sth->fetch){
      @$ref[5]  =~ s/(\d*)-(\d*)-(\d*)(.*)/$2\/$3\/$1/;
      @$ref[6]  =~ s/(\d*)-(\d*)-(\d*)(.*)/$2\/$3\/$1/;
      @$ref[7]  =~ s/(\d*)-(\d*)-(\d*)(.*)/$2\/$3\/$1/;
      @$ref[8]  =~ s/(\d*)-(\d*)-(\d*)(.*)/$2\/$3\/$1/;
      $medications .= "<tr>";
      if (@$ref[11] == 0){$medications .= "<td><em>@$ref[0] @$ref[1] @$ref[2] @$ref[3] @$ref[4] @$ref[10]</em></td>";}
      else {$medications .= "<td>@$ref[0] @$ref[1] @$ref[2] @$ref[3] @$ref[4] @$ref[10]</td>";}
      $medications .= qq{<td>@$ref[5]</td>
		  <td>@$ref[6]</td>
		  <td>@$ref[7]</td>
		  <td>@$ref[8]</td>
		  <td>@$ref[9]</td>
		  </font></tr>};
    }
    $medications .= qq!</table>!;
    
    ################################################################### Screening Tests
    
    $prevention = Screening_Prevention($patient_id, $sex, $DOB);
    
    ################################################################### Immunizations
    
    $immunizations = Immunizations($patient_id, $DOB);
    
    ################################################################### Counselling
    $counselling =  qq!<table>
	  <tr><th>Safety/injusry Prevention</th><td>--</td></tr>
	  <tr><th>STD/HIV Prevention</th><td>--</td></tr>
	  <tr><th>Pregnancy Prevention</th><td>--</td></tr>
	  <tr><th>Mental Health</th><td>--</td></tr>
	  <tr><th>Self-Breast Exam</th><td>--</td></tr>
	  <tr><th>Nutrition</th><td>--</td></tr>
	  <tr><th>Exercise</th><td>--</td></tr>
	  <tr><th>Smoking Cessation</th><td>--</td></tr>
	  <tr><th>Weight Reduction</th><td>--</td></tr>
	  <tr><th>Drub Abuse</th><td>--</td></tr>
	  <tr><th>Pain</th><td>--</td></tr>
	  </table>!;
    #################################################################  Chronic Care
    
    $chroniccare =   Chronic_Care_Assessment($patient_id);
    
    #################################  If no specific date is given, select most recent note for display
    my ($note_date, $note);
    if ((param('SubmitButton')!~/^\d\d-\d\d-\d\d\d\d$/)){
      $sql  = qq!SELECT MAX(date) FROM pnotes WHERE pid="$patient_id"!;
      $sth  = $dbh->prepare($sql);
      $sth  ->execute or die("Error executing SQL statement! $DBI::errstr");
      $ref  = $sth->fetch;
      $note_date = @$ref[0];
      $note_date =~ s/(\d+)-(\d+)-(\d+)/$1-$2-$3/;
#      $note = Print_Note($note_date, $patient_id);
    }
    
    #################################  If a specific date is given, select that note for display
    elsif (param('SubmitButton')=~/(^\d\d-\d\d-\d\d\d\d$)/){
      $note_date =$1;
      $note_date=~ s/(\d+)-(\d+)-(\d+)/$3-$1-$2/;
#      $note = Print_Note($note_date, $patient_id);
    }
    else{
#      $note = "No Encounters";
    }
    ###################################  Page Layout
    $page = qq{
        <table class="Container">
	  <tr>
            <td><h1>$name</h1></td>
	    <td rowspan='2'>$contact_information</td>
	    <td rowspan='2'>$additional</td>
	    <td >$extra</td>
          </tr>
	  <tr>
            <td>$identification</td>
            <td>Last updated: $date</td>
          </tr>
	  <tr>
            <td colspan='4'><fieldset><legend>Problem List</legend>$problems</fieldset></td>
          </tr>
	  <tr>
            <td colspan='4'><fieldset><legend>Medications</legend>$medications</fieldset></td>
          </tr>
	  <tr>
            <td rowspan='2'><fieldset><legend>Preventive Care</legend>$prevention</fieldset></td>
	    <td><fieldset><legend>Immunizations</legend>$immunizations</fieldset></td>
	    <td  rowspan='2'><fieldset><legend>Chronic Care</legend>$chroniccare</fieldset></td>
          </tr>
	  <tr><td><fieldset><legend>Counselling</legend>$counselling</fieldset></td>
          </tr>
	</table>
  };
  } else {
    $page = qq!<h1 class="comp">No patient identification offered</h1><h3>Please go to Main Screen to select a patient<h3>!;
  }
  return ($page);
} 

################################################################################
## 'Patient Demographics' page

sub Patient_Demographics {
  my $patient_id = shift;
  my ($sql, $sth, $ref, $tackon, $main, $pop);
  
  my ($id, $title, $language, $financial, $fname, $lname, $mname, $DOB, $street, $postal_code, $city, $state, $country_code, $ss, $occupation, $phone_home, $phone_biz, $phone_contact, $phone_cell, $status, $contact_relationship, $date, $sex, $referrer, $referrerID, $provider_id, $email, $ethnoracial, $interpretter, $migrantseasonal, $family_size, $monthly_income, $homeless, $financial_review, $pubpid, $pid, $genericname1, $genericval1, $genericname2, $genericval2, $hipaa_mail, $hipaa_voice, $healthcare_proxy, $phone_pharmacy, $allergies);
  
  my (@HeaderRow, @HeaderRow1, @HeaderRow2, @HeaderRow3, @HeaderRow4, @HeaderRow5, @HeaderRow6, @HeaderRow7, @HeaderRow8, @record,  @record1, @record2, @record3, @record4, @record5, @record6, @record7, @record8);
	
  my @keys = (
	      'title',
	      'language',
	      'financial',
	      'fname',
	      'lname',
	      'mname',
	      'DOB',
	      'street',
	      'postal_code',
	      'city',
	      'state',
	      'country_code',
	      'ss',
	      'occupation',
	      'phone_home',
	      'phone_biz',
	      'phone_contact',
	      'phone_cell',
	      'status',
	      'contact_relationship',
	      'sex',
	      'referrer',
	      'referrerID',
	      'provider_id',
	      'email',
	      'ethnoracial',
	      'interpretter',
	      'migrantseasonal',
	      'family_size',
	      'monthly_income',
	      'homeless',
	      'financial_review',
	      'pubpid',
	      'pid',
	      'genericname1',
	      'genericval1',
	      'genericname2',
	      'genericval2',
	      'hipaa_mail',
	      'hipaa_voice',
	      'healthcare_proxy',
	      'phone_pharmacy',
	      'allergies'
	     );
  if ($patient_id){
    ########################  Prepares an SQL statement to update the patient_data
    if (param('SubmitButton') eq 'Update'){
      my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday, $isdst) = localtime;
      $year =~ s/^(\d)/20/;
      $mon = $mon + 1;
      $sql = "UPDATE patient_data 
SET date='$year-$mon-$mday', ";
      foreach (@keys){
	if (param($_) =~ /^[-#]/){next;}
	$sql .= " $_ = "."'".param($_)."'".", ";
      }
      chop $sql;chop $sql;
      $sql .= qq! WHERE pid = '!.$patient_id.qq!'!;
      $sth = $dbh->prepare($sql);
      $sth->execute or die("\nError executing SQL statement! $DBI::errstr");
    }
    ##########################  Re-Displays the updated patient_data
    $sql = "SELECT * from patient_data 
WHERE pid = $patient_id";
    $sth = $dbh->prepare($sql);
    $sth->execute or die(print "\nError executing SQL statement! $DBI::errstr");
    $sth->bind_columns(
		       \$id, 
		       \$title, 
		       \$language, 
		       \$financial, 
		       \$fname, 
		       \$lname, 
		       \$mname, 
		       \$DOB, 
		       \$street, 
		       \$postal_code, 
		       \$city, 
		       \$state, 
		       \$country_code, 
		       \$ss, 
		       \$occupation, 
		       \$phone_home, 
		       \$phone_biz, 
		       \$phone_contact, 
		       \$phone_cell, 
		       \$status, 
		       \$contact_relationship,
		       \$date, 
		       \$sex, 
		       \$referrer, 
		       \$referrerID, 
		       \$provider_id, 
		       \$email, 
		       \$ethnoracial, 
		       \$interpretter, 
		       \$migrantseasonal, 
		       \$family_size, 
		       \$monthly_income, 
		       \$homeless, 
		       \$financial_review, 
		       \$pubpid, 
		       \$pid, 
		       \$genericname1, 
		       \$genericval1, 
		       \$genericname2, 
		       \$genericval2, 
		       \$hipaa_mail, 
		       \$hipaa_voice,
		       \$healthcare_proxy,
		       \$phone_pharmacy,
		       \$allergies
		      );
    while ($sth->fetch){
      my @row = (
		 "$title", 
		 "$language", 
		 "$financial", 
		 "$fname", 
		 "$lname", 
		 "$mname", 
		 "$DOB", 
		 "$street", 
		 "$postal_code", 
		 "$city", 
		 "$state", 
		 "$country_code", 
		 "$ss", 
		 "$occupation", 
		 "$phone_home", 
		 "$phone_biz", 
		 "$phone_contact", 
		 "$phone_cell", 
		 "$status", 
		 "$contact_relationship", 
		 "$sex", 
		 "$referrer", 
		 "$referrerID", 
		 "$provider_id", 
		 "$email", 
		 "$ethnoracial", 
		 "$interpretter", 
		 "$migrantseasonal", 
		 "$family_size", 
		 "$monthly_income", 
		 "$homeless", 
		 "$financial_review", 
		 "$pubpid", 
		 "$pid", 
		 "$genericname1", 
		 "$genericval1", 
		 "$genericname2", 
		 "$genericval2", 
		 "$hipaa_mail", 
		 "$hipaa_voice",
		 "$healthcare_proxy",
		 "$phone_pharmacy",
		 "$allergies"
		);
      ##############################################################################
      ## run through each of the fields in the patient_data file via bound variables
      foreach (@row){
	$pop = shift(@keys);
	push (@HeaderRow, $patient{$pop}[0]);
	if ($_){
	  ##########################################################################
	  # check the variable bound to the database to see if each field already has a value, in which case use that
	  if ($pop eq 'provider_id'){
	    push(@record,$cgi->textfield(-name=>$pop, -value=>Drop_Down_Item_List($dbh, 'users', 'lname',"id = '".$_."'")));
	  }else{push(@record,$cgi->textfield(-name=>$pop, -value=>$_));}
	}
	##########################################################################
	# use the database to fill the pop-up menu
	elsif ($pop eq ('state')){
	  push(@record,$cgi->popup_menu(-name=>$pop,
					-values=>[Drop_Down_Item_List($dbh, 'pop_places', 'state','')],
					-default=>$patient{$pop}[3]
				       )
	      );	  
	}elsif(($pop eq 'city') && ($state ne '')){
	  push(@record,$cgi->popup_menu(-name=>$pop,
					-values=>[Drop_Down_Item_List($dbh, 'pop_places', 'feature_name', "state = '".$state."'")] 
				       )
	      );
	}elsif($pop eq 'country_code'){
	  push(@record,$cgi->popup_menu(-name=>$pop,
					-values=>[Drop_Down_Item_List($dbh, 'geo_country_reference', 'countries_name','')],
					-default=>$patient{$pop}[3]
				       )
	      );	  
	}elsif($pop eq 'provider_id'){
	  push(@record,$cgi->popup_menu(-name=>$pop,
					-values=>[Drop_Down_Item_List($dbh, 'users','lname','')],
					-default=>$patient{$pop}[3]
				       )
	      );	
	}
	elsif($pop eq 'mname'){
	  push(@record, $cgi->textfield(-name=>$pop, -value=>$_));
	}
	elsif($pop eq 'street'){
	  push(@record, $cgi->textfield(-name=>$pop, -value=>$_));
	}
	elsif($pop eq 'postal_code'){
	  push(@record, $cgi->textfield(-name=>$pop, -value=>$_));
	}
	elsif($pop eq 'ss'){
	  push(@record, $cgi->textfield(-name=>$pop, -value=>$_, -default=>"###-##-####"));
	}
	elsif($pop eq'phone_home'){
	  push(@record, $cgi->textfield(-name=>$pop, -value=>$_, -default=>"###-###-####"));
	}
	elsif($pop eq 'phone_biz'){
	  push(@record, $cgi->textfield(-name=>$pop, -value=>$_, -default=>"###-###-####"));
	}
	elsif($pop eq 'phone_contact'){
	  push(@record, $cgi->textfield(-name=>$pop, -value=>$_, -default=>"###-###-####"));
	}
	elsif($pop eq 'phone_cell'){
	  push(@record, $cgi->textfield(-name=>$pop, -value=>$_, -default=>"###-###-####"));
	}
	elsif($pop eq 'email'){
	  push(@record, $cgi->textfield(-name=>$pop, -value=>$_, -default=>"----@---.---"));
	}
	elsif($pop eq 'healthcare_proxy'){
	  push(@record, $cgi->textfield(-name=>$pop, -value=>$_, -default=>"Healthcare Proxy"));
	}
	elsif($pop eq 'phone_pharmacy'){
	  push(@record, $cgi->textfield(-name=>$pop, -value=>$_, -default=>"###-###-####"));
	}
	elsif($pop eq 'allergies'){
	  push(@record, $cgi->textfield(-name=>$pop, -value=>$_));
	}
	else{
	  push(@record, $cgi->popup_menu(-name=>$pop,
					 -values=>$patient{$pop}[3]
					)
	      );
	}
      }
    }
    @HeaderRow1 = splice(@HeaderRow, 0, 5);
    @HeaderRow2 = splice(@HeaderRow, 0, 5);
    @HeaderRow3 = splice(@HeaderRow, 0, 5);
    @HeaderRow4 = splice(@HeaderRow, 0, 5);
    @HeaderRow5 = splice(@HeaderRow, 0, 5);
    @HeaderRow6 = splice(@HeaderRow, 0, 5);
    @HeaderRow7 = splice(@HeaderRow, 0, 5);
    @HeaderRow8 = splice(@HeaderRow, 0, 5);
    @record1 = splice(@record, 0, 5);
    @record2 = splice(@record, 0, 5);
    @record3 = splice(@record, 0, 5);
    @record4 = splice(@record, 0, 5);
    @record5 = splice(@record, 0, 5);
    @record6 = splice(@record, 0, 5);
    @record7 = splice(@record, 0, 5);
    @record8 = splice(@record, 0, 5);
    
    $main .= br();
    $main .= $cgi->table(caption(h1($fname," ",$lname)),
			 $cgi->Tr(th(\@HeaderRow1)),
			 $cgi->Tr(td(\@record1)),
			 $cgi->Tr(th(\@HeaderRow2)),
			 $cgi->Tr(td(\@record2)),
			 $cgi->Tr(th(\@HeaderRow3)),
			 $cgi->Tr(td(\@record3)),
			 $cgi->Tr(th(\@HeaderRow4)),
			 $cgi->Tr(td(\@record4)),
			 $cgi->Tr(th(\@HeaderRow5)),
			 $cgi->Tr(td(\@record5)),
			 $cgi->Tr(th(\@HeaderRow6)),
			 $cgi->Tr(td(\@record6)),
			 $cgi->Tr(th(\@HeaderRow7)),
			 $cgi->Tr(td(\@record7)),
			 $cgi->Tr(th(\@HeaderRow8)),
			 $cgi->Tr(td(\@record8)),
			 $cgi->Tr(th(\@HeaderRow)),
			 $cgi->Tr(td(\@record))
			);
  } else {
    $main = qq!<h1 class="comp">No patient identification offered</h1><h3>Please go to Main Screen to select a patient<h3>!;
  }

  return ($main);
}
################################################################################
## Update Record Page

sub Update_Record {
  my $patient_id = shift;
  my ($trade_name, $ingredient_name, $strength, $unit, $note, $route, $listing_seq_no, $problem_id, $frequency, $packsize, $refills, $active, $date, $sql, $sth, $Chief_complaint, $page, $id, $c, $pass);
  my %problems;
  my @plan;
  my (@new_med);

  if ($patient_id){
    ############################### Get problem list and medication list
    my ($title, $fname, $lname, $DOB, $age, $sex) = Get_Patient_Info($patient_id);
    $page .= qq!<table>!;
    $page .= qq!<tr><td><table><tr><th><h1 class="comp">$title $fname $lname</h1></th><td>DOB: $DOB</td><td>Age: $age</td><td>PID: $patient_id</td></tr></table></td></tr>!;
    $page .= qq"<tr><td><fieldset><legend>Problem List</legend>".(Get_Todays_Problem_List(0, $patient_id)).qq"</fieldset></td></tr>";
    $page .= qq!<tr><td><fieldset><legend>Medications</legend><table>!;
    $sql = qq!SELECT prescriptions.id, drug, dosage, unit, note, route_name, frequency, quantity, refills, active, problem_id
            FROM prescriptions LEFT JOIN tblroute ON tblroute.route_code=prescriptions.route 
	    WHERE patient_id="$patient_id" ORDER BY active DESC!;
    $sth = $dbh->prepare($sql);
    $sth ->execute;
    $sth->bind_columns(\($id, $trade_name, $strength, $unit, $note, $route, $frequency, $packsize, $refills, $active, $problem_id));
    $c = $sth->rows;
    if ($c==0){
      $page .=qq!<tr><td>No current medications</td></tr>!;
      $sth->fetch;
    }
    else {
      $page .= qq!<tr><td colspan="7"><select  name="Medications" default="" size=$c>!;
      while ($sth->fetch){
	$route =~ s/\s{2,200}(\w*)\s{2,200}/$1/;
	$frequency =~ s/\s{2,200}(\w*)\s{2,200}/$1/;
	if ($active == 0 && $pass == 0){
	  $page .= qq!<option disabled='disabled' value=''>Inactive</option>!;
	  $pass = 1;
	}
	$page .= qq!<option value="$id">$trade_name $strength $unit $note $route $frequency.  Amount: $packsize Refills: $refills</option>!;
      }
      $page .= qq!</select></td></tr>!;
    }
    $page .= qq!<tr><td></td></tr>!;
    if (param('Drug_Name_Search') || param('Medication_Name') || param('Medication_Strength') || param('Medication_Route') || param('Medication_Frequency') || param('Medication_Package') || (param('SubmitButton') eq 'Change Medication') || (param('SubmitButton') eq 'Stop Medication')){
      $new_med[$problem_id] = qq!!.Drug_Name_Search($patient_id, param('Todays_Problems'));
    } else {
      $new_med[$problem_id] = qq!<table>
	<tr><td>Drug Name</td><td><input type=text name="Drug_Name_Search" size='20' onBlur="shiftFocus('Drug')"></td></tr>
	</table>!;
    }
    if (param('Medication_Package')){
      $new_med[$problem_id] = qq!<table>
	<tr><td>Drug Name</td><td><input type=text name="Drug_Name_Search" size='20' onBlur="shiftFocus('Drug')"></td></tr>
	</table>!;     
    }
    $page .= qq!<tr valign=TOP><td>$new_med[$problem_id]</td></tr></table></fieldset></td></tr>!;
    $page .= qq!<tr><td><fieldset><legend>Screening</legend>!.Screening_Prevention($patient_id, $sex, $DOB).qq!</fieldset></td></tr>!;
    $page .= qq!<tr><td><fieldset><legend>Immuniunizations</legend>!.Immunizations($patient_id, $DOB).qq!</fieldset></td></tr>!;
    $page .= qq!<tr><td><fieldset><legend>Chronic Care Assessment</legend>!.Chronic_Care_Assessment($patient_id).qq!</fieldset></td></tr>!;
    $page .= qq!<tr><td><fieldset><legend>Counseling</legend></fieldset></td></tr>!;
    $page .= qq!</table>!;
  } else {
    $page = qq!<h1 class="comp">No patient identification offered</h1><h3>Please go to Main Screen to select a patient<h3>!;
  }

    return $page;
}  

################################################################################
## New Encounter Page

sub New_Encounter {
  my $patient_id = shift;
  my ($page, $note, $title, $fname, $lname, $DOB, $age, $sex, $cc, $hpi, $ros, $past_history, $pe, $dr, $decision_making) ;
  my ($sql, $sth, $ref, @ref);
  my ($id, $problem, $trade_name, $ingredient_name, $strength, $unit, $route, $frequency, $problem_id, $active, $listing_seq_no, $date, $key, $c);
  my ($new_med, $arrayref, @arrayref);
  my (@list, @values, %distinct, %routes);
  my (@concept, @date_added, @test_ordered);
  my (@problem_id, @plan);
  $page = "";
  if ($patient_id){
    ################################################
    ## Get List of Todays Problems (Either pick from old problems or add a new problem) given patient id
    ##  STEP 1
    if ((param('SubmitButton') eq "New Encounter") || ((param('Pick Problem') eq 'Yes') && (!param('Todays_Problems')))){
      $page = (Get_Todays_Problem_List(0, $patient_id));
    }
    ################################################
    ##  Print Formatted Note Page to be filled out if 'Todays Problems' have been entered from the select problems menu
    ##  STEP 2
    elsif (param('Todays_Problems')){
      $page = Note_Format($patient_id);
    }
    ################################################
    ##  Assessment and Plan
    ##  STEP 3
    else {
      #############################################
      ##  Insert Subjective/Objective information obtained in the visit into database
      if (param('SubmitButton') eq "Assessment and Plan"){Insert_SO($patient_id);}
      
      ###############################################
      ##  Print Subjective/Objective information and formatted Assessment and Plan
      $note = Print_Note(todays_date(), $patient_id);
      
      ###############################
      ##  Insert Tests into database
      if (param('Test Ordered')){
	my ($loinc_num, $problem_id, $shortname);
	($loinc_num, $problem_id, $shortname) = split(/\|/, param('Test Ordered'));
	$sql = qq!INSERT INTO tests
                (patient_id, loinc_num, date_ordered, provider_id, problem_id) 
                VALUES ("$patient_id", "$loinc_num", "!.todays_date().qq!", "!.param('hidden_provider_id').qq!", "$problem_id")!;
	$sth = $dbh -> prepare($sql);
	$sth ->execute;
	$plan[$problem_id] .= qq!Order $shortname\n!;
      }
      ###############################
      ##  Print Note and medical decision making
      my $Chief_complaint;
      my (@new_med, %old_med);
      $sql = qq!SELECT Chief_complaint
	    FROM pnotes
	    WHERE pid='!.$patient_id.qq!' and date='!.todays_date().qq!'!;
      $sth = $dbh -> prepare($sql);
      $sth ->execute;
      $sth ->bind_columns(\$Chief_complaint);
      $sth ->fetch;
      @problem_id = split(/ /, $Chief_complaint);
      
      ##############################################################################
      ##  Note with Assessment and Plan
      
      unless((param("SubmitButton") eq "Print") || (param("SubmitButton") eq "New Encounter")){
	$page .= qq!<table>
			<tr><td>$note</td></tr>
			<tr><td><h3>Medical Decision Making</h3></td></tr>!;
	$sql = qq!SELECT prescriptions.id, drug, dosage, unit, route_name, frequency , problem_id, active
                FROM prescriptions LEFT JOIN tblroute ON tblroute.route_code=prescriptions.route 
                WHERE patient_id='!.$patient_id.qq!'!;
	$sth = $dbh->prepare($sql);
	$sth ->execute;
	$sth->bind_columns(\($id, $trade_name, $strength, $unit, $route, $frequency, $problem_id, $active));
	$c = $sth->rows;
	if ($c==0){
	  $page .=qq!<tr><td>No current medications</td></tr>!;
	  $sth->fetch;
	}
	else {
	  $page .= qq!<tr><td colspan="7"><select  name="Medications" default="" size=$c>!;
	  while ($sth->fetch){
	    $route =~ s/\s{2,200}(\w*)\s{2,200}/$1/;
	    $frequency =~ s/\s{2,200}(\w*)\s{2,200}/$1/;
	    $old_med{"$trade_name"}=(["$strength", "$unit", "$route", "$frequency", "$problem_id", "$active"]);
	    $page .= qq!<option value="$trade_name $strength $unit $route $frequency $problem_id $active">!;
            if ($active==0){ 
              $page .= qq!<em>$trade_name $strength $unit $route $frequency</em></option>!;
	    }
	    else {
	      $page .= qq!$trade_name $strength $unit $route $frequency</option>!;
            }
	}
	  $page .= qq!</select></td></tr>
<tr><td></td></tr>!;
	}
	#########################################################################
	##   Assessment/Plan for each problem
	foreach $problem (@problem_id){
	  $sql   = qq!SELECT icd_9_cm_concepts.concept
		    FROM problem_list LEFT JOIN icd_9_cm_concepts ON problem_list.problem_id=icd_9_cm_concepts.id 
		    WHERE problem_list.patient_id="$patient_id" and problem_list.problem_id="$problem"! ;
	  $sth = $dbh->prepare($sql);
	  $sth ->execute;
	  $sth ->bind_columns(\($concept[$problem]));
	  $sth ->fetch;
	  #######################################################################
	  ##  Assessment
	  $page .= qq!<tr><td><b>$concept[$problem]</b></td></tr>
					<tr><td>Assessment</td></tr>
					<tr><td colspan=4><textarea name="Assessment $problem"  rows="5"  cols="100">!;
	  foreach $key (keys %old_med){
	    if (($old_med{$key}[4] == $problem) && ($old_med{$key}[5]==1)){
	      $page .= qq!$key $old_med{$key}[0] $old_med{$key}[1], $old_med{$key}[2] $old_med{$key}[3]\n!;
	    }
	  }
	  if (param("Assessment $problem")){$page .= param("Assessment $problem");}
	  $page .= qq!</textarea></td></tr>!;
	  #######################################################################
	  ##  Plan
	  $page .=qq!<tr><td>Plan</td></tr>
		   <tr><td colspan=4><textarea name="Plan $problem"  rows="5"  cols="100">!;
	  if (param("Plan $problem") || $plan[$problem]){$page .= param("Plan $problem").$plan[$problem];}
	  $page .=qq!</textarea></td></tr>!;
	  
	  ###### Diabetes
	  if ($concept[$problem]=~/250|790\.2/){
	    $page .= "<tr><td><input type='checkbox' name='DiabetesOrders' value='HgA1c' />HgA1c
                             <input type='checkbox' name='DiabetesOrders' value='Urine Microalbumin' />Urine Microalbumin
                             <input type='checkbox' name='LipidOrders' value='Lipids' />Lipids</td></tr>";
	  }
	  
	  ######## CHF
	  if ($concept[$problem]=~/428/){
	    $page .= qq!<tr><td><input type='checkbox' name='ThyroidOrders' value='TSH' />TSH
                               <input type='checkbox' name='LipidOrders' value='Lipids' />Lipids</td></tr>!;
	  }
	  
	  ######## Thyroid
	  if ($concept[$problem]=~/243|244/){
	    $page .= qq!<tr><td><input type='checkbox' name='ThyroidOrders' value='TSH' />TSH</td></tr>!;
	  }
	  
	  ######## Asthma
	  if ($concept[$problem]=~/493/){
	    $page .= qq!<tr><td><input type='checkbox' name='DiabetesOrders' value='HgA1c' />HgA1c
                           <input type='checkbox' name='DiabetesOrders' value='Urine Microalbumin' />Urine Microalbumin</td></tr>!;
	  }
	  
	  ######## Depression
	  if ($concept[$problem]=~/296|311/){
	    $page .= qq!<tr><td><input type='checkbox' name='DiabetesOrders' value='HgA1c' />HgA1c
                           <input type='checkbox' name='DiabetesOrders' value='Urine Microalbumin' />Urine Microalbumin</td></tr>!;
	  }
	  
	  #######################################################################
	  ##  New Meds
	  
	  $page .= qq!<tr valign=TOP><td>!;
	  $page .= Drug_Name_Search($patient_id, $problem).qq!</td></tr>!;
	  ########################################################################
	  ##  Order Tests
	  if ((param('SubmitButton') eq "Order Test")
	      || (param('SubmitButton') eq "Pick Observation Class Type")
	      || (param('SubmitButton') eq "Pick Observation Class")
	      || (param('SubmitButton') eq "Pick Method")
	      || (param('SubmitButton') eq "Pick System")){
	    my ($testClass, $testComponent, $testSystem);
	    if (param("classtype")){
	      $test_ordered[$problem] = Test_Search(param("classtype"), $problem);
	    }
	    elsif (param("Test Class")) {
	      $test_ordered[$problem] = Test_Search(param("Test Class"), $problem);
	    }
	    elsif (param("Test Component")){
	      ($testClass, $testComponent) = split(/ /, param("Test Component"));
	      $test_ordered[$problem] = Test_Search($testClass, $problem, $testComponent);
	    }
	    elsif (param("Test System")){
	      ($testClass, $testComponent, $testSystem) = split(/ /, param("Test System"));
	      $test_ordered[$problem] = Test_Search($testClass, $problem, $testComponent, $testSystem);
	    }
	  }
	  else {
	    $test_ordered[$problem] = qq!<tr><td><input type="submit" name="SubmitButton" value="Pick Observation Class Type"></td>
	<td>Class Type</td><td><select name="classtype">
	<option value="1">Laboratory Class</option>
	<option value="2">Clinical Class</option>
	<option value="3">Claims Attachment</option>
	<option value="4">Surveys</option></td></tr>!;
	  }
	  $page .= qq!$test_ordered[$problem]!;
	}
	###########################################################################
	##  Health Maintenance/Prevention
	$page .= qq!<tr><td>Health Maintenance</td></tr>
	    <tr><td colspan=4><textarea name="Health_Maintenance_Assessment" rows='5' cols='100'>!;
	($title, $fname, $lname, $DOB, $age, $sex) = Get_Patient_Info($patient_id);
	$decision_making= Screening_Prevention($patient_id, $sex, $DOB);
	$decision_making =~ s/<\/tr>/, /sg;
	$decision_making =~ s/<[0-9a-zA-Z\/'%=, ]+>/ /sg;
	$decision_making =~ s/(\d\d\d\d-\d\d-\d\d)\d\d\d\d-\d\d-\d\d/$1/sg;
#	$decision_making =~ s/, $//sg;
	$page .= $decision_making;
	$page .= qq"</textarea></td></tr>";
	if ($sex eq 'M'){
	  $page .= qq!<tr><td><input type='checkbox' name='PreventionOrders' value='PSA' />PSA</td></tr>!;
	}
	if ($sex eq 'F'){
	  $page .= qq!<tr><td><input type='checkbox' name='PreventionOrders' value='Mammogram' />Mammogram</td>
	  <td><input type='checkbox' name='PreventionOrders' value='PAP' />PAP</td></tr>!;
	}
	$page .= qq!<tr><td><input type='checkbox' name='PreventionOrders' value='FOB' />FOB</td>
<td><input type='checkbox' name='PreventionOrders' value='Colonoscopy' />Colonoscopy</td>
<td><input type='checkbox' name='PreventionOrders' value='DEXA' />DEXA</td>
<td><input type='checkbox' name='PreventionOrders' value='PPD' />PPD</td></tr>!;
	$page .= qq"<tr><td colspan='4'><textarea name='Health_Maintenance_Plan' rows='5' cols='100'>";
	if (param('Health_Maintenance_Plan')){$page .= param('Health_Maintenance_Plan');}
	$page .= qq!</textarea></td></tr>
	          <tr><td>Additional Note</td></tr>
	          <tr><td colspan='4'><textarea name='Additional_Note' rows='5' cols='100'></textarea></td></tr>!;
	$page .= qq!</table>!;
      }
    }
    ###########################################################################
    ##  Print
    ##  STEP 4
    if (param("SubmitButton") eq "Print"){
      my $sql2 = qq!UPDATE pnotes
	          SET assessment_plan="!;
      my $done = 0;
      foreach $problem (@problem_id){
	$sql   = qq!SELECT icd_9_cm_concepts.concept
		FROM problem_list LEFT JOIN icd_9_cm_concepts ON problem_list.problem_id=icd_9_cm_concepts.id 
		WHERE problem_list.patient_id="$patient_id" and problem_list.problem_id="$problem"! ;
	$sth = $dbh->prepare($sql);
	$sth ->execute;
	$sth ->bind_columns(\($concept[$problem]));
	$sth ->fetch;
	$sql2 .= qq!$concept[$problem]: \nAssessment - !.param("Assessment $problem").qq!;  \nPlan - !.param("Plan $problem").qq!.\n!;

	##### Chronic Care by problem
	if (param('DiabetesOrders') eq "HgA1c" && $concept[$problem]=~/250|790\.2/){
	  $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, provider_id, problem_id) VALUES ('!.$patient_id.qq!', '17855-8', '!.todays_date().qq!', '!.param('hidden_provider_id').qq!', "$problem")!;
	  $sth=$dbh->prepare($sql);
	  $sth->execute;
	}
	if (param('DiabetesOrders') eq "Urine Microalbumin" && $concept[$problem]=~/250|790\.2/){
	  $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, provider_id, problem_id) VALUES ('!.$patient_id.qq!', '34535-5', '!.todays_date().qq!', '!.param('hidden_provider_id').qq!', "$problem")!;
	  $sth=$dbh->prepare($sql);
	  $sth->execute;
	}
	if (param('LipidOrders') eq "Lipids"){
	  ##### Only insert lipid results once, even though there may be several problems relevant to lipids
	  if ($done==0){
	    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, provider_id, problem_id) VALUES ('!.$patient_id.qq!', '35200-5', '!.todays_date().qq!', '!.param('hidden_provider_id').qq!', "$problem")!;
	    $sth=$dbh->prepare($sql);
	    $sth->execute;
	    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, provider_id, problem_id) VALUES ('!.$patient_id.qq!', '35217-9', '!.todays_date().qq!', '!.param('hidden_provider_id').qq!', "$problem")!;
	    $sth=$dbh->prepare($sql);
	    $sth->execute;
	    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, provider_id, problem_id) VALUES ('!.$patient_id.qq!', '35197-3', '!.todays_date().qq!', '!.param('hidden_provider_id').qq!', "$problem")!;
	    $sth=$dbh->prepare($sql);
	    $sth->execute;
	    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, provider_id, problem_id) VALUES ('!.$patient_id.qq!', '35198-1', '!.todays_date().qq!', '!.param('hidden_provider_id').qq!', "$problem")!;
	    $sth=$dbh->prepare($sql);
	    $sth->execute;
	  }
	  $done = 1;
	}
	if (param('CHFOrders') eq "Echo" && $concept[$problem]=~/428/){
	}
	if (param('ThyroidOrders') eq 'TSH'){
	  $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, provider_id, problem_id) VALUES ('!.$patient_id.qq!', '3016-3', '!.todays_date().qq!', '!.param('hidden_provider_id').qq!', "$problem")!;
	  $sth=$dbh->prepare($sql);
	  $sth->execute;
	}
      }

      #####  Screening/Prevention not related to Chronic Care Management
      if (param('PreventionOrders') eq 'PSA'){
	$sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, provider_id, problem_id) VALUES ('!.$patient_id.qq!', '35741-8', '!.todays_date().qq!', '!.param('hidden_provider_id').qq!', '19315')!;
	$sth=$dbh->prepare($sql);
	$sth->execute;     
      }
      if (param('PreventionOrders') eq 'Mammogram'){
	$sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, provider_id, problem_id) VALUES ('!.$patient_id.qq!', '24606-6', '!.todays_date().qq!', '!.param('hidden_provider_id').qq!', '18912')!;
	$sth=$dbh->prepare($sql);
	$sth->execute;      
      }
      if (param('PreventionOrders') eq 'PAP'){
	$sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, provider_id, problem_id) VALUES ('!.$patient_id.qq!', '19771-5', '!.todays_date().qq!', '!.param('hidden_provider_id').qq!', '15350')!;
	$sth=$dbh->prepare($sql);
	$sth->execute;      
      }
      if (param('PreventionOrders') eq 'FOB'){
	$sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, provider_id, problem_id) VALUES ('!.$patient_id.qq!', '2334-8', '!.todays_date().qq!', '!.param('hidden_provider_id').qq!', '19759')!;
	$sth=$dbh->prepare($sql);
	$sth->execute;      
      }
      if (param('PreventionOrders') eq 'Colonoscopy'){
	$sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, provider_id, problem_id) VALUES ('!.$patient_id.qq!', '28022-2', '!.todays_date().qq!', '!.param('hidden_provider_id').qq!', '19759')!;
	$sth=$dbh->prepare($sql);
	$sth->execute;      
      }
      if (param('PreventionOrders') eq 'DEXA'){
	$sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, provider_id, problem_id) VALUES ('!.$patient_id.qq!', '38268-9', '!.todays_date().qq!', '!.param('hidden_provider_id').qq!', '19179')!;
	$sth=$dbh->prepare($sql);
	$sth->execute;      
      }
      if (param('PreventionOrders') eq 'PPD'){
	$sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, provider_id, problem_id) VALUES ('!.$patient_id.qq!', '39208-4', '!.todays_date().qq!', '!.param('hidden_provider_id').qq!', '2255')!;
	$sth=$dbh->prepare($sql);
	$sth->execute;      
      }
      if (param('Health_Maintenance_Assessment')){
	$sql2 .= qq!Health Maintenance\nAssessment - I recommend !.param('Health_Maintenance_Assessment').qq!;  \nPlan - !.param('Health_Maintenance_Plan').qq!.\n!;
      }
      if (param('Additional_Note')){
	$sql2 .= qq!Additional Note\n!.param('Additional_Note').qq!.\n!;
      }
      substr($sql2, -1) = qq!" WHERE pid='!.$patient_id.qq!' and date='!.todays_date().qq!'!;
      $sth = $dbh->prepare($sql2);
      $sth ->execute;
      $note = Print_Note(todays_date(),$patient_id);
      $page .= qq!<table class="Container">
		<tr><td>$note</td></tr>
               </table>!;
    }
  } else {
    $page = qq!<h1 class="comp">No patient identification offered</h1><h3>Please go to Main Screen to select a patient<h3>!;
  }

  return $page;
}

################################################################################
## Print Prescriptions

sub Print_Prescriptions {
  my $patient_id = shift;
  #  my 
}

################################################################################
##  Print Note
##  Passed:   note date, patient id
##  Return:  formatted note

sub Print_Note {

  my ($note_date, $patient_id) = @_;
  if ($note_date =~/(\d\d)-(\d\d)-(\d\d\d\d)/){$note_date=~s/(\d\d)-(\d\d)-(\d\d\d\d)/$3-$1-$2/;}
  my ($sql, $sth, $note);
  my ($title, $fname, $lname, $DOB, $sex, $problem, $c, $CC, $HPI, $ROS, $FSH, $Medications, $PMH, $PE);
  my (@location, @quality, @quantity, @timing, @setting, @aggrevating_relieving, @associated_manifestations, @patient_reaction);

  #############################################  Get Information
  $sql = qq!SELECT title, fname, lname, DOB, sex 
FROM patient_data 
WHERE pid='!.$patient_id.qq!'!;
  $sth = $dbh->prepare($sql);
  $sth ->execute;
  $sth ->bind_columns(\($title, $fname, $lname, $DOB, $sex));
  $sth ->fetch;
  my ($assessment_plan, $Chief_complaint, $concerns, $Location, $Quality, $Quantity, $Timing, $Setting, $Aggravating_relieving, $Associated_manifestations, $Patient_reaction, $Pain, $General, $Skin, $Head, $Eyes, $Ears, $Nose_sinuses, $Mouth_throat, $Neck, $Breasts, $Respiratory, $Cardiac, $Gi, $Gu, $Male, $Female, $Vascular, $Neurological, $Musc, $Endo, $Heme, $Psych, $Other_symptoms, $Nutritional, $Psych_needs, $Educational_needs, $Blood_pressure, $Heart_rate, $Resp_rate, $Temp, $Blood_glucose, $Height, $Weight, $General_exam, $Skin_exam, $Eye_exam, $Ear_exam, $Nose_exam, $Mouth_exam, $Neck_exam, $Thyroid_exam, $Lymph_exam, $Chest_exam, $Lung_exam, $Heart_exam, $Breast_exam, $Abdomen_exam, $Rectal_exam, $Prostate_exam, $Testespenis_exam, $External_female_exam, $Speculum_exam, $Internal_exam, $Extremities_exam, $Pulses_exam, $Neurologic_exam);
  my (@problem_id, @date_added, @concept);
  $sql = qq!SELECT assessment_plan, Chief_complaint, concerns,  Location, Quality, Quantity, Timing, Setting, Aggravating_relieving, Associated_manifestations, Patient_reaction, Pain, General, Skin, Head, Eyes, Ears, Nose_sinuses, Mouth_throat, Neck, Breasts, Respiratory, Cardiac, Gi, Gu, Male, Female, Vascular, Neurological, Musc, Endo, Heme, Psych, Other_symptoms, Nutritional, Psych_needs, Educational_needs, Blood_pressure, Heart_rate, Resp_rate, Temp, Blood_glucose, Height, Weight, General_exam, Skin_exam, Eye_exam, Ear_exam, Nose_exam, Mouth_exam, Neck_exam, Thyroid_exam, Lymph_exam, Chest_exam, Lung_exam, Heart_exam, Breast_exam, Abdomen_exam, Rectal_exam, Prostate_exam, Testespenis_exam, External_female_exam, Speculum_exam, Internal_exam, Extremities_exam, Pulses_exam, Neurologic_exam
FROM pnotes
WHERE pid='!.$patient_id.qq!' and date='!.$note_date.qq!'!;
  $sth = $dbh->prepare($sql);
  $sth ->execute;
  $sth ->bind_columns(\$assessment_plan, \$Chief_complaint, \$concerns, \$Location, \$Quality, \$Quantity, \$Timing, \$Setting, \$Aggravating_relieving, \$Associated_manifestations, \$Patient_reaction, \$Pain, \$General, \$Skin, \$Head, \$Eyes, \$Ears, \$Nose_sinuses, \$Mouth_throat, \$Neck, \$Breasts, \$Respiratory, \$Cardiac, \$Gi, \$Gu, \$Male, \$Female, \$Vascular, \$Neurological, \$Musc, \$Endo, \$Heme, \$Psych, \$Other_symptoms, \$Nutritional, \$Psych_needs, \$Educational_needs, \$Blood_pressure, \$Heart_rate, \$Resp_rate, \$Temp, \$Blood_glucose, \$Height, \$Weight, \$General_exam, \$Skin_exam, \$Eye_exam, \$Ear_exam, \$Nose_exam, \$Mouth_exam, \$Neck_exam, \$Thyroid_exam, \$Lymph_exam, \$Chest_exam, \$Lung_exam, \$Heart_exam, \$Breast_exam, \$Abdomen_exam, \$Rectal_exam, \$Prostate_exam, \$Testespenis_exam, \$External_female_exam, \$Speculum_exam, \$Internal_exam, \$Extremities_exam, \$Pulses_exam, \$Neurologic_exam);
  $sth->fetch;
  $DOB =~  s/(\d*)-(\d*)-(\d*)/$2\/$3\/$1/;
  $note_date =~  s/(\d*)-(\d*)-(\d*)/$2\/$3\/$1/;

  ############################################## Chief Complaint ($CC)

  @problem_id=split(/ /,$Chief_complaint);
  $CC = qq!<table><tr><th><h3>Chief Complaint<h3></th></tr>!;
  foreach $problem (@problem_id){
    $sql   = qq!SELECT icd_9_cm_concepts.concept, date_added 
	FROM problem_list LEFT JOIN icd_9_cm_concepts ON problem_list.problem_id=icd_9_cm_concepts.id 
	WHERE problem_list.patient_id="!.$patient_id.qq!" and problem_list.problem_id="$problem"!;
    $sth = $dbh->prepare($sql);
    $sth ->execute;
    $sth ->bind_columns(\($concept[$problem], $date_added[$problem]));
    while ($sth->fetch){
      $date_added[$problem]=~ s/(\d+)-(\d+)-(\d+)/$2\/$3\/$1/;
      $CC .= qq!<tr><td colspan=3>$concept[$problem] First Noted: $date_added[$problem]</td></tr>!;
    }
  }
  $CC .= qq!</table>!;

  ###############################################  History of Present Illness ($HPI)
  $HPI = qq!<table><tr><th><h3>HPI</h3></th></tr>!;
  if ($Location =~/\t/){
    @location = split (/\t/m, $Location);
  }
  elsif ($Location){push(@location, $Location);}
  if ($Quality =~/\t/){
    @quality = split(/\t/m, $Quality);
  }
  elsif ($Quality){push(@quality, $Quality);}
  if ($Quantity =~/\t/){
    @quantity = split(/\t/m, $Quantity);
  }
  elsif ($Quantity){push (@quantity, $Quantity);}
  if ($Timing =~/\t/){
    @timing = split(/\t/m, $Timing);
  }
  elsif ($Timing){push (@timing, $Timing);}
  if (Setting=~/\t/){
    @setting = split(/\t/m, $Setting);
  }
  elsif ($Setting){push(@setting, $Setting);}
  if ($Aggravating_relieving=~/\t/){
    @aggrevating_relieving = split(/\t/m, $Aggravating_relieving);
  }
  elsif ($Aggravating_relieving){push(@aggrevating_relieving, $Aggravating_relieving);}
  if ($Associated_manifestations=~/\t/){
    @associated_manifestations = split(/\t/m, $Associated_manifestations);
  }
  elsif($Associated_manifestations){push(@associated_manifestations, $Associated_manifestations);}
  if ($Patient_reaction=~/\t/){
    @patient_reaction=split(/\t/m, $Patient_reaction);
  }
  elsif ($Patient_reaction){push(@patient_reaction, $Patient_reaction);}
  $c=0;
  foreach $problem (@problem_id){
    $HPI .= qq!<tr><th colspan=3><b>$concept[$problem]</b></th><td colspan=5></td></tr>!;
    if ($concept[$problem] =~/\[V/){$HPI .= qq!<tr><td colspan=1></td><td><b>Concerns: </b>$concerns</td></tr>!;}
    else{
      foreach (@location){
	if ($_ =~ /\[$problem\]/){
	  $_ =~ s/(.*)\[$problem\]/$1/;
	  $HPI .= qq!<tr><td colspan=1></td><td><b>Location: </b>$_</td></tr>!;
	  $c=1;
	}
      }
      foreach (@quality){
	if ($_ =~ /\[$problem\]/){
	  $_ =~ s/(.*)\[$problem\]/$1/;
	  $HPI .= qq!<tr><td colspan=1></td><td><b>Quality: </b>$_</td></tr>!;
	  $c=1;
	}
      }
      foreach (@quantity){
	if ($_ =~ /\[$problem\]/){
	  $_ =~ s/(.*)\[$problem\]/$1/;
	  $HPI .= qq!<tr><td colspan=1></td><td><b>Quantity: </b>$_</td></tr>!;
	  $c=1;
	}
      }
      foreach (@timing){
	if ($_ =~ /\[$problem\]/){
	  $_ =~ s/(.*)\[$problem\]/$1/;
	  $HPI .= qq!<tr><td colspan=1></td><td><b>Timing: </b>$_</td></tr>!;
	  $c=1;
	}
      }
      foreach (@setting){
	if ($_ =~ /\[$problem\]/){
	  $_ =~ s/(.*)\[$problem\]/$1/;
	  $HPI .= qq!<tr><td colspan=1></td><td><b>Setting: </b>$_</td></tr>!;
	  $c=1;
	}
      }
      foreach (@aggrevating_relieving){
	if ($_ =~ /\[$problem\]/){
	  $_ =~ s/(.*)\[$problem\]/$1/;
	  $HPI .= qq!<tr><td colspan=1></td><td><b>Aggravating Relieving: </b>$_</td></tr>!;
	  $c=1;
	}
      }
      foreach (@associated_manifestations){
	if ($_ =~ /\[$problem\]/){
	  $_ =~ s/(.*)\[$problem\]/$1/;
	  $HPI .= qq!<tr><td colspan=1></td><td><b>Associated Manifestations: </b>$_</td></tr>!;
	  $c=1;
	}
      }
      foreach (@patient_reaction){
	if ($_ =~ /\[$problem\]/){
	  $_ =~ s/(.*)\[$problem\]/$1/;
	  $HPI .= qq!<tr><td colspan=1></td><td><b>Patient Reaction: </b>$_</td></tr>!;
	  $c=1;
	}
      }
    }
  }
  if($c==0){
    if ($Location){$HPI .= qq!<tr><td colspan=1></td><td><b>Location: </b>$Location</td></tr>!;}
    if ($Quality){$HPI .= qq!<tr><td colspan=1></td><td><b>Quality: </b>$Quality</td></tr>!;}
    if ($Quantity){$HPI .= qq!<tr><td colspan=1></td><td><b>Quantity: </b>$Quantity</td></tr>!;}
    if ($Timing){$HPI .= qq!<tr><td colspan=1></td><td><b>Timing: </b>$Timing</td></tr>!;}
    if ($Setting){$HPI .= qq!<tr><td colspan=1></td><td><b>Setting: </b>$Setting</td></tr>!;}
    if ($Aggravating_relieving){$HPI .= qq!<tr><td colspan=1></td><td><b>Aggravating Relieving: </b>$Aggravating_relieving</td></tr>!;}
    if ($Associated_manifestations){$HPI .= qq!<tr><td colspan=1></td><td><b>Associated Manifestations: </b>$Associated_manifestations</td></tr>!;}
    if ($Patient_reaction){$HPI .= qq!<tr><td colspan=1></td><td><b>Patient Reaction: </b>$Patient_reaction</td></tr>!;}
  }
  $HPI .= qq!</table>!;

  ############################### Review of Systems ($ROS)

  if ($Pain || $General || $Skin || $Head || $Eyes || $Ears || $Nose_sinuses || $Mouth_throat || $Neck || $Breasts || $Respiratory || $Cardiac || $Gi || $Gu || $Male  || $Female || $Vascular || $Neurological ||$Musc || $Endo ||$Heme || $Psych || $Other_symptoms || $Nutritional || $Psych_needs || $Educational_needs) {
    $ROS = qq!<table><tr><th><h3>Review of Systems: </h3></th></tr><tr><td>!;
  }
  if ($Pain){
    if ($Pain eq "No pain"){
	$ROS .= "$title $fname $lname has no pain; ";
    } else {
	$ROS .= "Pain: $title $fname $lname has $Pain;  ";
    }
  }
  if ($General){$ROS .= qq!General Systems:$General;  !;}
  if ($Skin){$ROS .= qq!Skin: $Skin;  !;}
  if ($Head){$ROS .= qq!Head:$Head;  !;}
  if ($Eyes){$ROS .= qq!Eyes:$Eyes;  !;}
  if ($Ears){$ROS .= qq!Ears:$Ears;  !;}
  if ($Nose_sinuses){$ROS .= qq!Nose and Sinuses:$Nose_sinuses;  !;}
  if ($Mouth_throat){$ROS .= qq!Mouth and Throat:$Mouth_throat;  !;}
  if ($Neck){$ROS .= qq!Neck:$Neck;  !;}
  if ($Breasts){$ROS .= qq!Breasts:$Breasts;  !;}
  if ($Respiratory){$ROS .= qq!Respiratory:$Respiratory;  !;}
  if ($Cardiac){$ROS .= qq!Cardiac:$Cardiac;  !;}
  if ($Gi){$ROS .= qq!Gastrointestinal:$Gi;  !;}
  if ($Gu){$ROS .= qq!Urologic:$Gu;  !;}
  if ($Male){$ROS .= qq!Male Genital:$Male;  !;}
  if ($Female){$ROS .= qq!Female Genital:$Female;  !;}
  if ($Vascular){$ROS .= qq!Peripheral Vascular:$Vascular;  !;}
  if ($Neurological){$ROS .= qq!Neurological:$Neurological;  !;}
  if ($Musc){$ROS .= qq!Musculo-Skelatal:$Musc;  !;}
  if ($Endo){$ROS .= qq!Endocrine:$Endo;  !;}
  if ($Heme){$ROS .= qq!Hematologic:$Heme;  !;}
  if ($Psych){$ROS .= qq!Psychiatric:$Psych;  !;}
  if ($Other_symptoms){$ROS .= qq!Other Symptoms:$Other_symptoms;  !;}
  if ($Nutritional){$ROS .= qq!Nutritional Needs:$Nutritional;  !;}
  if ($Psych_needs){$ROS .= qq!Psychological Needs:$Psych_needs;  !;}
  if ($Educational_needs){$ROS .= qq!Educational Needs:$Educational_needs; !;}
  if ($ROS){substr($ROS, -2) = qq!.</td></tr></table>!;}

  ###############################################################
  ##  Past Problems  ($PMH)
  ##  Past_Problems returns a reference to arrays @past, @chronic, @ongoing, @acute
  ##  Each array containts the elements: $problem_id, $concept, $code, $date_added, $active, $chronic
  my ($problem_id, $concept, $code, $date_added, $active, $chronic, $pastref, $chronicref, $ongoingref, $acuteref, $key);
 $PMH = qq!

<table>
<tr><th><h3>Past Medical History: </h3></th></tr>
<tr><td></td><td>Problem</td><td>ICD-9 Code</td><td>Date First Noted</td></tr>

!;
  ($pastref, $chronicref, $ongoingref, $acuteref)=Past_Problems($patient_id);
  
 if (@$pastref){
   $PMH .= qq!<tr><td>Past Problems</td>!;
   for  ($key=0; $key<=$#$pastref;$key++){
     if ($key==0){
       $PMH .= qq!<td>$$pastref[$key][1]</td><td>$$pastref[$key][2]</td><td>$$pastref[$key][3]</td></tr>!;
     }
     else {
       $PMH .= qq!<tr><td></td><td>$$pastref[$key][1]</td><td>$$pastref[$key][2]</td><td>$$pastref[$key][3]</td></tr>!;
     }
   }
 }
 if (@$chronicref){
   $PMH.=qq!<tr><td>Chronic Problems</td>!;
   for  ($key=0; $key<=$#$chronicref;$key++){
     if ($key==0){
       $PMH .= qq!<td>$$chronicref[$key][1]</td><td>$$chronicref[$key][2]</td><td>$$chronicref[$key][3]</td></tr>!;
     }
     else{
       $PMH .= qq!<tr><td></td><td>$$chronicref[$key][1]</td><td>$$chronicref[$key][2]</td><td>$$chronicref[$key][3]</td></tr>!;
     }
   }
 }
 if (@$ongoingref){
   $PMH.=qq!<tr><td>Ongoing Problems</td>!;
   for  ($key=0; $key<=$#$ongoingref;$key++){
     if ($key==0){
       $PMH .= qq!<td>$$ongoingref[$key][1]</td><td>$$ongoingref[$key][2]</td><td>$$ongoingref[$key][3]</td></tr>!;
     }
     else{
       $PMH .= qq!<tr><td></td><td>$$ongoingref[$key][1]</td><td>$$ongoingref[$key][2]</td><td>$$ongoingref[$key][3]</td></tr>!;	
     }
   }
 }
 if (@$acuteref){
   $PMH.=qq!<tr><td>Acute Problems</td>!;
   for  ($key=0; $key<=$#$acuteref;$key++){
     if ($key==0){
       $PMH .= qq!<td>$$acuteref[$key][1]</td><td>$$acuteref[$key][2]</td><td>$$acuteref[$key][3]</td></tr>!;
     }
     else{
       $PMH .= qq!<tr><td></td><td>$$acuteref[$key][1]</td><td>$$acuteref[$key][2]</td><td>$$acuteref[$key][3]</td></tr>!;		
     }
   }
 }
 $PMH .= qq!</table>!;
  ############################################## Medications
my ($id, $trade_name, $strength, $unit, $route, $frequency);
$sql = qq!SELECT prescriptions.id, drug, dosage, unit, route_name, frequency, active
FROM prescriptions LEFT JOIN tblroute ON tblroute.route_code=prescriptions.route 
WHERE patient_id="$patient_id"!;
$sth = $dbh->prepare($sql);
$sth ->execute;
$sth ->bind_columns(\($id, $trade_name, $strength, $unit, $route, $frequency, $active));
$c = $sth->rows;
  if ($c>0){
    $Medications .= qq!<tr><td colspan="8"><table>!;
    $Medications .= qq!<tr><th><h3>Medications</h3></th></tr><tr><td colspan="8">!;
    while ($sth->fetch){
      $route =~ s/\s{2,200}(\w*)\s{2,200}/$1/;
      $frequency =~ s/\s{2,200}(\w*)\s{2,200}/$1/;
      if ($active==1){$Medications .= qq!$trade_name $strength $unit $route $frequency<br>!;}
    }
  substr($Medications, -4)=qq!</td></tr>!;
  $Medications .= qq!</table></td></tr></table>!;
  } else {$Medications ="";}

  ############################################## Family and Social History

  my ($coffee, $alcohol, $drug_use, $sleep_patterns, $exercise_patterns, $std, $reproduction, $sexual_function, $self_breast_exam, $self_testicle_exam, $seatbelt_use, $counseling, $hazardous_activities, $last_social_history,$last_breast_exam, $last_mammogram, $last_gynocological_exam, $last_psa, $last_prostate_exam, $last_physical_exam, $last_sigmoidoscopy_colonoscopy, $last_fecal_occult_blood, $last_ppd, $last_bone_density, $history_mother, $history_father, $history_siblings, $history_offspring, $history_spouse, $relatives_cancer, $relatives_tuberculosis, $relatives_diabetes, $relatives_hypertension, $relatives_heart_problems, $relatives_stroke, $relatives_epilepsy, $relatives_mental_illness, $relatives_suicide, $date, $pid, $name_1, $value_1, $name_2, $value_2, $additional_history);
  $sql = qq!SELECT coffee, alcohol, drug_use, sleep_patterns, exercise_patterns, std, reproduction, sexual_function, self_breast_exam, self_testicle_exam, seatbelt_use, counseling, hazardous_activities, last_social_history, last_breast_exam, last_mammogram, last_gynocological_exam, last_psa, last_prostate_exam, last_physical_exam, last_sigmoidoscopy_colonoscopy, last_fecal_occult_blood, last_ppd, last_bone_density, history_mother, history_father, history_siblings, history_offspring, history_spouse, relatives_cancer, relatives_tuberculosis, relatives_diabetes, relatives_hypertension, relatives_heart_problems, relatives_stroke, relatives_epilepsy, relatives_mental_illness, relatives_suicide, date, pid, name_1, value_1, name_2, value_2, additional_history 
FROM history_data
WHERE pid='!.$patient_id.qq!'!;
$sth = $dbh->prepare($sql);
  $sth ->execute;
  $sth ->bind_columns(\$coffee, \$alcohol, \$drug_use, \$sleep_patterns, \$exercise_patterns, \$std, \$reproduction, \$sexual_function, \$self_breast_exam, \$self_testicle_exam, \$seatbelt_use, \$counseling, \$hazardous_activities, \$last_social_history, \$last_breast_exam, \$last_mammogram, \$last_gynocological_exam, \$last_psa, \$last_prostate_exam, \$last_physical_exam, \$last_sigmoidoscopy_colonoscopy, \$last_fecal_occult_blood, \$last_ppd, \$last_bone_density, \$history_mother, \$history_father, \$history_siblings, \$history_offspring, \$history_spouse, \$relatives_cancer, \$relatives_tuberculosis, \$relatives_diabetes, \$relatives_hypertension, \$relatives_heart_problems, \$relatives_stroke, \$relatives_epilepsy, \$relatives_mental_illness, \$relatives_suicide, \$date, \$pid, \$name_1, \$value_1, \$name_2, \$value_2, \$additional_history);
$sth->fetch;
 if ($coffee || $alcohol || $drug_use || $sleep_patterns || $exercise_patterns || $std || $reproduction || $sexual_function || $self_breast_exam || $self_testicle_exam || $seatbelt_use || $counseling || $hazardous_activities || $history_mother || $history_father || $history_siblings || $history_offspring || $history_spouse || $relatives_cancer || $relatives_tuberculosis || $relatives_diabetes || $relatives_hypertension || $relatives_heart_problems || $relatives_stroke || $relatives_epilepsy || $relatives_mental_illness || $relatives_suicide){
  $FSH = qq!<table>!;
}

############################################### Social History
  if ($coffee || $alcohol || $drug_use || $sleep_patterns || $exercise_patterns || $std || $reproduction || $sexual_function || $self_breast_exam || $self_testicle_exam || $seatbelt_use || $counseling || $hazardous_activities){
    $FSH .= qq!<tr><th><h3>Past Social History:</h3></th></tr><tr><td>!;
    if ($coffee){$FSH .= qq!Coffee: $coffee;  !;}
    if ($alcohol){$FSH .= qq!Alcohol: $alcohol;  !;}
    if ($drug_use){$FSH .= qq!Drug Use: $drug_use;  !;}
    if ($sleep_patterns){$FSH .= qq!Sleep Patterns: $sleep_patterns;  !;}
    if ($exercise_patterns){$FSH .= qq!Exercise Patterns: $exercise_patterns;  !;}
    if ($std){$FSH .= qq!Sexually Transmitted Disease: $std;  !;}
    if ($reproduction){$FSH .= qq!reproduction: $reproduction;  !;}
    if ($sexual_function){$FSH .= qq!Sexual Function: $sexual_function;  !;}
    if ($self_breast_exam){$FSH .= qq!Self Breast Exam: $self_breast_exam;  !;}
    if ($self_testicle_exam){$FSH .= qq!Self Testicle Exam: $self_testicle_exam;  !;}
    if ($seatbelt_use){$FSH .= qq!Seatbelt Use: $seatbelt_use;  !;}
    if ($counseling){$FSH .= qq!Counseling: $counseling;  !;}
    if ($hazardous_activities){$FSH .= qq!Hasardous Activities: $hazardous_activities;  !;}
    $FSH =~ s/;  $/./;
    $FSH .= qq!</td></tr>!;
  }
  
  ################################################ Family History
  if ($history_mother || $history_father || $history_siblings || $history_offspring || $history_spouse || $relatives_cancer || $relatives_tuberculosis || $relatives_diabetes || $relatives_hypertension || $relatives_heart_problems || $relatives_stroke || $relatives_epilepsy || $relatives_mental_illness || $relatives_suicide){
    $FSH .= qq!<tr><td colspan='8'><h3>Family History:</h3></td></tr><tr><td>!;
    if ($history_mother){$FSH .= qq!Mothers History: $history_mother;  !;}
    if ($history_father){$FSH .= qq!Fathers History: $history_father;  !;}
    if ($history_siblings){$FSH .= qq!Siblings History: $history_siblings;  !;}
    if ($history_offspring){$FSH .= qq!Childrens History: $history_offspring;  !;}
    if ($history_spouse){$FSH .= qq!Spouses History: $history_spouse;  !;}
    if ($relatives_cancer){$FSH .= qq!Relatives with cancer: $relatives_cancer;  !;}
    if ($relatives_tuberculosis){$FSH .= qq!Relatives with tuberculosis: $relatives_tuberculosis;  !;}
    if ($relatives_diabetes){$FSH .= qq!Relative with Diabetes: $relatives_diabetes;  !;}
    if ($relatives_hypertension){$FSH .= qq!Relative with Hypertension: $relatives_hypertension;  !;}
    if ($relatives_heart_problems){$FSH .= qq!Relatives with heart problems: $relatives_heart_problems;  !;}
    if ($relatives_stroke){$FSH .= qq!relatives with stroke: $relatives_stroke;  !;}
    if ($relatives_epilepsy){$FSH .= qq!Relatives with epilepsy: $relatives_epilepsy;  !;}
    if ($relatives_mental_illness){$FSH .= qq!Relatives with mental illness: $relatives_mental_illness;  !;}
    if ($relatives_suicide){$FSH .= qq!Relatives with a history of suicide: $relatives_suicide;  !;}
    $FSH =~ s/;  $/./;
    $FSH .= qq!</td></tr>!;
  }
  $FSH .= qq!</table>!;

  ################################################## Physical Exam
  $PE .= qq!<table>
<tr><th><h3>Physical Exam:</h3></th></tr>!;
  if ($Blood_pressure){$PE .= qq!<tr><td>Vital Signs:</td><td>Blood Pressure:$Blood_pressure;  !;}
  if ($Heart_rate){$PE .= qq!Heart Rate: $Heart_rate;  !;}
  if ($Resp_rate){$PE .= qq!Respiratory Rate: $Resp_rate;  !;}
  if ($Temp){$PE .= qq!Temperature: $Temp;  !;}
  if ($Blood_glucose){$PE .= qq!Blood Glucose: $Blood_glucose;  !;}
  if ($Height){
    $Height =~s/(\d)(.*)(\d+)(.*)/$1 Feet $3 Inches/;
    $PE .= qq!Height: $Height;  !;
  }
  if ($Weight){$PE .= qq!Weight: $Weight;  !;}
  if ($Blood_pressure || $Heart_rate || $Resp_rate || $Temp || $Blood_glucose || $Height || $Weight){
    $PE =~ s/;  $/.<\/td><\/tr>/;
  }
  if ($General_exam){$PE .= qq!<tr><td>General Exam:</td><td>$General_exam</td></tr>!;}
  if ($Skin_exam){$PE .= qq!<tr><td>Skin Exam:</td><td>$Skin_exam</td></tr>!;}
  if ($Eye_exam){$PE .= qq!<tr><td>Eye Exam:</td><td>$Eye_exam</td></tr>!;}
  if ($Ear_exam){$PE .= qq!<tr><td>Ear Exam:</td><td>$Ear_exam</td></tr>!;}
  if ($Nose_exam){$PE .= qq!<tr><td>Nose Exam:</td><td>$Nose_exam</td></tr>!;}
  if ($Mouth_exam){$PE .= qq!<tr><td>Mouth Exam:</td><td>$Mouth_exam</td></tr>!;}
  if ($Neck_exam){$PE .= qq!<tr><td>Neck Exam:</td><td>$Neck_exam</td></tr>!;}
  if ($Thyroid_exam){$PE .= qq!<tr><td>Thyroid Exam:</td><td>$Thyroid_exam</td></tr>!;}
  if ($Lymph_exam){$PE .= qq!<tr><td>Lymph Exam:</td><td>$Lymph_exam</td></tr>!;}
  if ($Chest_exam){$PE .= qq!<tr><td>Chest Exam:</td><td>$Chest_exam</td></tr>!;}
  if ($Lung_exam){$PE .= qq!<tr><td>Lung Exam:</td><td>$Lung_exam</td></tr>!;}
  if ($Heart_exam){$PE .= qq!<tr><td>Heart Exam:</td><td>$Heart_exam</td></tr>!;}
  if ($Breast_exam){$PE .= qq!<tr><td>Breast Exam:</td><td>$Breast_exam</td></tr>!;}
  if ($Abdomen_exam){$PE .= qq!<tr><td>Abdomen Exam:</td><td>$Abdomen_exam</td></tr>!;}
  if ($Rectal_exam){$PE .= qq!<tr><td>Rectal Exam:</td><td>$Rectal_exam</td></tr>!;}
  if ($Prostate_exam){$PE .= qq!<tr><td>Prostate Exam:</td><td>$Prostate_exam</td></tr>!;}
  if ($Testespenis_exam){$PE .= qq!<tr><td>Testes/Penis Exam:</td><td>$Testespenis_exam</td></tr>!;}
  if ($External_female_exam){$PE .= qq!<tr><td>External Female Genital Exam:</td><td>$External_female_exam</td></tr>!;}
  if ($Speculum_exam){$PE .= qq!<tr><td>Speculum Exam:</td><td>$Speculum_exam</td></tr>!;}
  if ($Internal_exam){$PE .= qq!<tr><td>Internal Exam:</td><td>$Internal_exam</td></tr>!;}
  if ($Extremities_exam){$PE .= qq!<tr><td>Extremities Exam:</td><td>$Extremities_exam</td></tr>!;}
  if ($Pulses_exam){$PE .= qq!<tr><td>Pulses Exam:</td><td>$Pulses_exam</td></tr>!;}
  if ($Neurologic_exam){$PE .= qq!<tr><td>Neurologic Exam:</td><td>$Neurologic_exam</td></tr>!;}
  if ($General_exam || $Skin_exam || $Eye_exam || $Ear_exam || $Nose_exam || $Mouth_exam || $Neck_exam || $Thyroid_exam || $Lymph_exam || $Chest_exam || $Lung_exam || $Heart_exam || $Breast_exam || $Abdomen_exam || $Rectal_exam || $Prostate_exam || $Testespenis_exam || $External_female_exam || $Speculum_exam || $Internal_exam || $Extremities_exam || $Pulses_exam || $Neurologic_exam){
    $PE .= qq!</table>!;
  }

  ######################################  Assessment and Plan ($assessment_plan)
  if ($assessment_plan){
#    $assessment_plan =~ s/([\n;:])/$1<br>/sg;
    $assessment_plan =~ s/(.*\[.*\]:)/<h4>$1<\/h4>/mg;
    $assessment_plan =~ s/Assessment/<i>Assessment<\/i>/sg;
    $assessment_plan =~ s/Plan/<i>Plan<\/i>/sg;
    $assessment_plan =~ s/Health Maintenance/<h4>Health Maintenance<\/h4>/sg;
    $assessment_plan =~ s/Additional Note/<h4>Additional Note<\/h4>/sg;
  }

  #######################################  Assemble Note
  $note = qq!

<table>
<tr>
<td><table width=100%><tr><th><h2>$title $fname $lname</h2></th><th><h2> DOB:  $DOB</h2></th>
<th><h2>Progress Note</h2></th><th><h2>Date: $note_date</h2></th>
</tr></table></td></tr>
<tr><td>$CC</td></tr>
<tr><td>$HPI</td></tr>
!;

if ($ROS){
    $note .= qq!<tr><td>$ROS</td></tr>!;
}
$note .= qq!<tr><td>$PMH</td></tr>!;
if ($FSH){
    $note .= qq!<tr><td>$FSH</td></tr>!;
}
if ($Medications){
    $note .=qq!<tr><td>$Medications</td></tr>!;
}

  $note .= qq!
<table class="Container">
<tr><td colspan=8>$PE</td></tr>
<tr><td colspan=8><table>
<tr><th><h3>Assessment and Plan:</h3></th></tr>
<tr><td>$assessment_plan</td></tr>
<tr></tr><tr></tr>
<tr><td>Edwin R. Young, M.D.</td></tr>
</table>
!;

  return $note;
}

###################################################################################################
##  Subroutine:  Search for medications by trade name

sub Drug_Name_Search {
  my ($patient_id, $problem_id) = @_;
  my ($c, $sql, $sth, $listing_seq_no, $firm_seq_no, $trade_name, $ingredient_name, $strength, $unit, $route_code, $route_name, $packsize, $packtype, $frequency, $note, $date, $problem);
  my (@new_med);

  ##################################
  ##  Pick Medication

  ##  STEP 1: Fill in name to search
  unless (param('Drug_Name_Search') || param('Hidden_Medication_Name') || param('Drug_Name_Completed') || (param('SubmitButton') eq 'Change Medication')){
    $new_med[$problem] = qq!<table>
	<tr><td>Drug Name</td><td><input type=text name="Drug_Name_Search" size='20' onBlur="shiftFocus('Drug')"></td>!;
  }

  ##  STEP 2: Pick medication from search list
  if (param('Drug_Name_Search')){
    $new_med[$problem] = qq!<table>
<tr><td><select name='Medication_Name' onBlur="shiftFocus('Medication_Name')">!;
    $sql=qq!SELECT DISTINCT listings.trade_name, formulat.ingredient_name 
	  FROM listings LEFT JOIN formulat ON (listings.listing_seq_no=formulat.listing_seq_no) !;
    $sql.=qq!WHERE (trade_name REGEXP '!.param('Drug_Name_Search').qq!') AND listings.strength IS NOT NULL !;
    $sql .=qq!ORDER BY trade_name!;
    $sth= $dbh->prepare($sql);
    $sth-> execute;
    $sth->bind_columns(\($trade_name, $ingredient_name));
    while ($sth  ->fetch){
      $new_med[$problem] .= qq!<option value="$trade_name">$trade_name</option>!;
    }
    $new_med[$problem] .= qq!</select></td>!;
  }

  ##  STEP 3:  Pick the strength - also the important step in changing medication strength
  if ((param('Medication_Name') && !param('Medication_Strength') && !(param('SubmitButton') eq 'Stop Medication'))){
    $new_med[$problem] = qq!<table>
<tr><td>!;
    $new_med[$problem] .= param('Medication_Name');
    $new_med[$problem].=qq!</td><td><select name='Medication_Strength' onBlur="shiftFocus('Medication_Strength')">!;
    $sql=qq!SELECT DISTINCT strength, unit !;
    $sql.=qq!FROM listings !;
    if (param('Medications') && !param('Medication_Name')){
      $sql .= qq!WHERE trade_name="$trade_name" !;
    } else {
      $sql .= qq!WHERE trade_name = '!.param('Medication_Name').qq!' !;
    }
    $sql .= qq!ORDER by strength!;
    $sth = $dbh->prepare($sql);
    $sth->execute;
    $sth->bind_columns(\($strength, $unit));
    while ($sth->fetch){
      $new_med[$problem] .= qq!<option value="$strength $unit">$strength $unit</option>!;
    }
    $new_med[$problem] .= qq!</select></td><td>Note: <input type='text' name='Medication_Note' />!;
  }

  ## SETP 4: Pick the route
  if (param('Medication_Strength') && !param('Medication_Route')){
    $new_med[$problem] = qq!<table>
<tr><td>!;
    $new_med[$problem].=param('Hidden_Medication_Name');
    $new_med[$problem].=qq! !.param('Medication_Strength').qq!</td><td><select name='Medication_Route' onBlur="shiftFocus('Medication_Route')">!;
    $sql=qq!SELECT DISTINCT route_code, route_name !;
    $sql.=qq!FROM routes LEFT JOIN listings ON routes.listing_seq_no=listings.listing_seq_no 
               WHERE trade_name = '!;
#    if (param('Hidden_Medications')){$sql .= $trade_name;} else {
$sql.= param('Hidden_Medication_Name');
#}
    $sql.=qq!'!;p
    $sth = $dbh->prepare($sql);
    $sth->execute;
    $sth->bind_columns(\($route_code, $route_name));
    $c = $sth->rows;
    if ($c==0){
      $new_med[$problem] .=qq!<option value="ORAL 001">ORAL</option>!;
      $sth->fetch;
    }
    else {
      while ($sth->fetch){
	$new_med[$problem] .= qq!<option value="$route_code $route_name">$route_name</option>!;
      }
    }
    $new_med[$problem] .= qq!</select></td>!;
  }

  ## STEP 5: Pick Frequency
  if (param('Medication_Route') && !param('Medication_Frequency')){
    ($route_code, $route_name)=split(/ /, param('Medication_Route'));
    $new_med[$problem] = qq!<table>
<tr><td>!;
    $new_med[$problem].=param('Hidden_Medication_Name');
    $new_med[$problem].=qq! !.param('Hidden_Medication_Strength').qq! $route_name</td><td><select name="Medication_Frequency" onBlur="shiftFocus('Medication_Frequency')">
			<option value='Once Daily'>Once Daily</option>
			<option value='Once Daily As Needed'>Once Daily As Needed</option>
			<option value='Twice Daily'>Twice Daily</option>
			<option value='Twice Daily As Needed'>Twice Daily As Needed</option>
			<option value='Three Times Daily'>Three Times Daily</option>
			<option value='Three Times Daily As Needed'>Three Times Daily As Needed</option>
			<option value='Three Times Daily Before Meals'>Three Times Daily Before Meals</option>
			<option value='Every Six Hours'>Every Six Hours</option>
			<option value='Every Six Hours As Needed'>Every Six Hours As Needed</option>
			<option value='Every Four Hours'>Every Four Hours</option>
			<option value='Every Four Hours As Needed'>Every Four Hours As Needed</option>
			<option value='Every Three Hours'>Every Three Hours</option>
			<option value='Every Three Hours As Needed'>Every Three Hours As Needed</option>
			<option value='Every Two Hours'>Every Two Hours</option>
			<option value='Every Two Hours As Needed'>Every Two Hours As Needed</option>
                        <option value='Every Other Day'>Every Other Day</option>
			<option value='Once Weekly'>Once Weekly</option>
			<option value='Once Weekly as Needed'>Once Weekly as Needed</option>
			<option value='Once Monthly'>Once Monthly</option>
                        <option value='Every Five Minutes As Needed'>Every Five Minutes As Needed</option>
			</select></td>!;
  }

  ## STEP 6: Pick Package size
  if (param('Medication_Frequency') && !param('Medication_Package')){
    ($strength, $unit)=split(/ /, param('Hidden_Medication_Strength'));
    ($route_code, $route_name)=split(/ /, param('Hidden_Medication_Route'));
    $sql = qq!SELECT DISTINCT packsize , packtype 
FROM packages INNER JOIN listings ON packages.listing_seq_no=listings.listing_seq_no INNER JOIN routes ON packages.listing_seq_no=routes.listing_seq_no  
WHERE listings.trade_name='!;
    $sql.=param('Hidden_Medication_Name');
    $sql .= qq!' AND listings.strength="$strength" AND listings.unit="$unit" AND routes.route_name="$route_name" 
ORDER BY packtype, packsize DESC!;
    $sth = $dbh->prepare($sql);
    $sth->execute;
    $sth->bind_columns(\($packsize, $packtype));
    $new_med[$problem] = qq!<table>
<tr><td>!;
    $new_med[$problem].=param('Hidden_Medication_Name');
    $new_med[$problem].=qq! !.param('Hidden_Medication_Strength').qq! $route_name</td><td><select name="Medication_Package">!;
    if ($sth->rows == 0){$new_med[$problem] .= qq!<option value="NA NA">No package information availble</option>!;}
    while ($sth->fetch){
      $new_med[$problem] .= qq!<option value="$packsize $packtype">$packsize !.PackageTranslate($packtype).qq!</option>!;
    }
    $new_med[$problem] .= qq!</select></td><td><select name="Medication_Refills" onBlur="shiftFocus('Medication_Package')">!;
    for ($c=0; $c<=10; $c++){$new_med[$problem].=qq!<option value="$c">$c</option>!;}
    $new_med[$problem].=qq!</select></td></tr></table>!;
  }
  ###############################
  ##  Step 7: Insert Meds into database
  if (param('Medication_Package')){
    ($strength, $unit)=split(/ /, param('Hidden_Medication_Strength'));
    ($route_code, $route_name)=split(/ /, param('Hidden_Medication_Route'));
    ($packsize, $packtype)=split(/ /, param('Medication_Package'));
    $sql = qq!SELECT DISTINCT listings.listing_seq_no 
FROM listings INNER JOIN packages ON listings.listing_seq_no=packages.listing_seq_no INNER JOIN routes ON packages.listing_seq_no=routes.listing_seq_no 
WHERE trade_name='!.param('Hidden_Medication_Name').qq!' AND strength="$strength" AND packsize="$packsize" AND packtype="$packtype" AND routes.route_code="$route_code"!;
    $sth = $dbh->prepare($sql);
    $sth->execute;
    $sth->bind_columns(\($listing_seq_no));
    $new_med[$problem] .= qq!<table>
<tr><td>!;
    while ($sth->fetch){}
    $date  =  todays_date();
    $sql   =  qq!INSERT INTO prescriptions 
               (drug, dosage, unit, date_added, route, frequency, listing_seq_no, quantity, package, refills, patient_id, problem_id, provider_id!;
      if (param('Hidden_Medication_Note')){$sql .= qq!, note!;}
      $sql .= qq!) VALUES (
"!.param('Hidden_Medication_Name').qq!", 
"$strength", 
"$unit", 
"$date", 
"$route_code", 
'!.param('Hidden_Medication_Frequency').qq!', 
"$listing_seq_no", 
"$packsize", 
"$packtype", 
'!.param('Medication_Refills').qq!', 
"$patient_id", 
"$problem_id", 
'!.param('hidden_provider_id').qq!'!;
     if (param('Hidden_Medication_Note')){$sql .= qq!, '!.param('Hidden_Medication_Note').qq!'!;}
     $sql .=qq!)!;
    $sth   = $dbh->prepare($sql);
    $sth   -> execute;
  }
  ###############################
  ##  Pick Meds to Discontinue in database
  if (param('SubmitButton') eq 'Stop Medication'){
    foreach(param('Medications')){
      $sql = qq!UPDATE prescriptions 
                SET active='0', date_stopped="!.todays_date().qq!" 
                WHERE id="$_"!;
    }
    $sth = $dbh->prepare($sql);
    $sth -> execute;
  }

  ################################
  ##  Change Medication

  if (param('SubmitButton') eq 'Change Medication'){
    unless (param('New_Strength') || param('New_Frequency') || param('New_Quantity') || param('New_Package') || param('New_Refills')){
      $sql .= qq!SELECT drug, listing_seq_no, note FROM prescriptions where id='!.param('Medications').qq!'!;
      $sth = $dbh->prepare($sql);
      $sth->execute;
      $sth->bind_columns(\$trade_name, \$listing_seq_no, \$note);
      $sth->fetch;
      $new_med[$problem].= qq!<table>
<tr><th>Medication</th><th>Strength</th><th>Frequency</th><th>Note</th><th>Quantity</th><th>Package</th><th>Refills</th></tr>
<tr><td><select name='New_Medication'><option value='!.param('Medications').qq!'>$trade_name</option></select></td>!.qq!<td><select name='New_Strength'>!;
      foreach $c (Drop_Down_Item_List($dbh, 'listings', 'strength', qq!trade_name="$trade_name"!, 'New Strength')){
	$new_med[$problem] .= qq!<option value="$c">$c</option>!;
      }
      $new_med[$problem] .= qq!</select></td><td><select name='New_Frequency'>
	<option value='Once Daily'>Once Daily</option>
	<option value='Once Daily As Needed'>Once Daily As Needed</option>
        <option value='Twice Daily'>Twice Daily</option>
        <option value='Twice Daily As Needed'>Twice Daily As Needed</option>
      	<option value='Three Times Daily'>Three Times Daily</option>
	<option value='Three Times Daily As Needed'>Three Times Daily As Needed</option>
        <option value='Three Times Daily Before Meals'>Three Times Daily Before Meals</option>
     	<option value='Every Four Hours'>Every Four Hours</option>
       	<option value='Every Four Hours As Needed'>Every Four Hours As Needed</option>
      	<option value='Every Six Hours'>Every Six Hours</option>
       	<option value='Every Six Hours As Needed'>Every Six Hours As Needed</option>
       	<option value='Every Other Day'>Every Other Day</option>
       	<option value='Every Other Day as Needed'>Every Other Day as Needed</option>
      	<option value='Once Weekly'>Once Weekly</option>
      	<option value='Once Weekly as Needed'>Once Weekly as Needed</option>
        <option value='Once Monthly'>Once Monthly</option>
       	<option value='Every Five Minutes As Needed'>Every Five Minutes As Needed</option>
       	</select></td>!;
      $new_med[$problem] .= qq!<td><input type='text' name='note' value="$note"></td><td><select name='New_Quantity'>!;
      foreach $c (Drop_Down_Item_List($dbh, 'packages INNER JOIN listings ON packages.listing_seq_no=listings.listing_seq_no', 'packsize', qq!listings.trade_name="$trade_name"!, 'New Quantity')){
	$new_med[$problem] .= qq!<option value="$c">$c</option>!;
      }
      $new_med[$problem].=qq!</select></td>!;
      $new_med[$problem].=qq!<td><select name='New_Package'>!;
      foreach $c (Drop_Down_Item_List($dbh, 'packages INNER JOIN listings ON packages.listing_seq_no=listings.listing_seq_no', 'packtype', qq!listings.trade_name="$trade_name"!, 'New Package')){
	$new_med[$problem] .= qq!<option value="$c">!.PackageTranslate($c).qq!</option>!;
      }
      $new_med[$problem].=qq!</select></td>!;    
      $new_med[$problem].=qq!<td><select name='New_Refills'>!;
      for ($c=0; $c<=10; $c++){$new_med[$problem].=qq!<option value="$c">$c</option>!;}
      $new_med[$problem] .= qq!</select></td>!;
    } else {
      $sql = qq!UPDATE prescriptions SET dosage='!.param('New_Strength').qq!', frequency='!.param('New_Frequency').qq!', quantity='!.param('New_Quantity').qq!', package='!.param('New_Package').qq!', refills='!.param('New_Refills').qq!', date_modified="!.todays_date().qq!", problem_id="!.param('Todays_Problems').qq!" !;
      if (param('note')){$sql .= qq!, note='!.param('note').qq!' !;}
      $sql .= qq!WHERE id=!.param('New_Medication');
      $sth = $dbh->prepare($sql);
      $sth->execute;
    }
  }
  $new_med[$problem] .= qq!</tr></table>!;
  return $new_med[$problem];
}

#######################################################################################
## Subroutine: Search for medication by ingredient name. 
sub Ingredient_Name_Search {
  my $ingredient_name_search = shift;
  my $problem_id = shift;
  my ($sql, $sth, $arrayref, $ref, $c, $key, $listing_seq_no, $trade_name, $ingredient_name, $strength, $unit, $new_med);
  my (@list, @values, %distinct, %routes);
  $sql         = qq!SELECT DISTINCT listings.listing_seq_no, listings.trade_name, formulat.ingredient_name, formulat.strength, formulat.unit 
		FROM listings LEFT JOIN formulat ON listings.listing_seq_no=formulat.listing_seq_no 
		WHERE (ingredient_name REGEXP "$ingredient_name_search") 
		ORDER BY trade_name, formulat.strength DESC!;
  $sth         = $dbh->prepare($sql);
  $sth         -> execute;
  $sth         ->bind_columns(\($listing_seq_no, $trade_name, $ingredient_name, $strength, $unit));
  while ($sth  ->fetch){
    push (@list, [$listing_seq_no, $trade_name, $ingredient_name, $strength, $unit]);
  }
  for $arrayref (@list){push(@values, @{$arrayref}[1]." (".@{$arrayref}[2].") ".@{$arrayref}[3]." ".@{$arrayref}[4]);}
  $c           = 0;
  for (@values){$distinct{$_} = $list[$c][0]; $c++;}   # This produces an hash named distinct: the keys are the distinct formulations, the values are the listing_seq_no
  undef @values;undef @list;
  $sql         = "SELECT route_code, route_name 
FROM routes 
WHERE listing_seq_no = ?";
  $sth         = $dbh->prepare($sql);
  foreach $key (keys %distinct){
    $sth       ->execute($distinct{$key});
    while ($ref= $sth->fetch){                                                                 # This produces an hash named routes;  
      $routes{[$key,@$ref[0],$distinct{$key},$problem_id]}=$key.", ".@$ref[1];    # the keys are the distinct formulations with route_code and problem_idattached, 
    }                                                                                          # the values are the route_name.
  }
  $new_med      = qq!<table><td><td>!;
  $new_med     = $cgi->scrolling_list(-name=>'Medication_Name', 
				      -size=>'10',
				      -values=>[keys %routes], 
				      -labels=>\%routes);
  $new_med    .= qq!</td><td><select name="Medication_Frequency">
			<option value='Once Daily'>Once Daily</option>
			<option value='Once Daily As Needed'>Once Daily As Needed</option>
			<option value='Twice Daily'>Twice Daily</option>
			<option value='Twice Daily As Needed'>Twice Daily As Needed</option>
			<option value='Three Times Daily'>Three Times Daily</option>
			<option value='Three Times Daily As Needed'>Three Times Daily As Needed</option>
			<option value='Every Six Hours'>Every Six Hours</option>
			<option value='Every Four Hours'>Every Six Hours As Needed</option>
			<option value='Every Six Hours As Needed'>Every Six Hours As Needed</option>
			<option value='Every Four Hours'>Every Four Hours</option>
			<option value='Every Four Hours As Needed'>Every Four Hours As Needed</option>
			<option value='Once Weekly'>Once Weekly</option>
			<option value='Once Weekly as Needed'>Once Weekly as Needed</option>
			<option value='Once Monthly'>Once Monthly</option>
			</select></td>!;
  $new_med    .= qq!<td><input type="submit" name="SubmitButton" value='Pick Frequency'></td></tr></table>!;
  return $new_med;
}

###################################################################################
## Search for tests

sub Test_Search {
  my $class = $_[0];
  my $problem_id = $_[1];
  my $component = $_[2];
  my $system = $_[3];
  my ($sql, $sth, $loinc_num, $shortname, $species, $return);
  my %CLASS = (
	       'BDYCRC.ATOM'=>'Body circumference atomic',
	       'BDYCRC.MOLEC'=>'Body circumference molecular',
	       'BDYHGT.ATOM'=>'Body height atomic',
	       'BDYHGT.MOLEC'=>'Body height molecular',
	       'BDYSURF.ATOM'=>'Body surface atomic',
	       'BDYTMP.ATOM'=>'Body temperature atomic',
	       'BDYTMP.MOLEC'=>'Body temperature molecular',
	       'BDYTMP.TIMED.MOLE'=>'Body temperature timed molecular',
	       'BDYWGT.ATOM'=>'Body weight atomic',
	       'BDYWGT.MOLEC'=>'Body weight molecular',
	       'BP.ATOM'=>'Blood pressure atomic',
	       'BP.CENT.MOLEC'=>'Blood pressure central molecular',
	       'BP.MOLEC'=>'Blood pressure molecular',
	       'BP.PSTN.MOLEC'=>'Blood pressure positional molecular',
	       'BP.TIMED.MOLEC'=>'Blood pressure timed molecular',
	       'BP.VENOUS.MOLEC'=>'Blood pressure venous molecular',
	       'CARD.US'=>'Cardiac Ultrasound (was US.ECHO)',
	       'CLIN'=>'Clinical NEC (not elsewhere classified)',
	       'DENTAL'=>'Dental',
	       'DOC.CLINRPT'=>'Clinical report documentation',
	       'DOC.REF'=>'Referral documentation',
	       'DOC.REF.CTP'=>'Clinical trial protocol document',
	       'DOCUMENT.REGULATORY'=>'Regulatory documentation',
	       'ED'=>'Emergency Department (DEEDS)',
	       'EKG.ATOM'=>'Electrocardiogram atomic',
	       'EKG.IMP'=>'Electrocardiogram impression',
	       'EKG.MEAS'=>'Electrocardiogram measures',
	       'ENDO.GI'=>'Gastrointestinal endoscopy',
	       'EYE'=>'Eye',
	       'EYE.CONTACT_LENS'=>'Ophthalmology Contact Lens',
	       'EYE.GLASSES'=>'Ophthalmology Glasses: Lens Manufacturer (LM) & Prescription',
	       'EYE.HETEROPHORIA'=>'Ophthalmology Heterophoria',
	       'EYE.PX'=>'Ophthalmology Physical Findings',
	       'EYE.REFRACTION'=>'Ophthalmology Refraction',
	       'EYE.RETINAL_RX'=>'Ophthalmology Treatments',
	       'EYE.TONOMETRY'=>'Ophthalmology Tonometry',
	       'EYE.US'=>'Ophthalmology Ultrasound',
	       'EYE.VISUAL_FIELD'=>'Ophthalmology Visual Field',
	       'FUNCTION'=>'Functional status (e.g. Glasgow)',
	       'GEN.US'=>'General Ultrasound',
	       'H&P.HX'=>'History',
	       'H&P.PX'=>'Physical',
	       'H&P.SURG'=>'PROC  Surgical procedure',
	       'HEMODYN.ATOM'=>'Hemodynamics anatomic',
	       'HEMODYN.MOLEC'=>'Hemodynamics molecular',
	       'HRTRATE.ATOM'=>'Heart rate atomic',
	       'HRTRATE.MOLEC'=>'Heart rate molecular',
	       'HRTRATE.TIMED.MOL'=>'Heart rate timed molecular',
	       'IO.TUBE'=>'Input/Output of tube',
	       'IO_IN.ATOM'=>'Input/Output atomic',
	       'IO_IN.MOLEC'=>'Input/Output molecular',
	       'IO_IN.SUMMARY'=>'Input/Output summary',
	       'IO_IN.TIMED.MOLEC'=>'Input/Output timed molecular',
	       'IO_IN_SALTS+CALS'=>'Input/Output electrolytes and calories',
	       'IO_OUT.ATOM'=>'Input/Output. Atomic',
	       'IO_OUT.MOLEC'=>'Input/Output. Molecular',
	       'IO_OUT.TIMED.MOLE'=>'Input/Output Timed Molecular',
	       'NEONAT'=>'Neonatal measures  OB.US Obstetric ultrasound',
	       'OBGYN'=>'Obstetrics/gynecology',
	       'PANEL.BDYTMP'=>'Body temperature order set',
	       'PANEL.BP'=>'Blood pressure order set',
	       'PANEL.CARDIAC'=>'Cardiac studies order set',
	       'PANEL.FUNCTION'=>'Function order set',
	       'PANEL.H&P'=>'History & physical order set',
	       'PANEL.IO'=>'Input/Output order set',
	       'PANEL.OB.US'=>'Obstetrical ultrasound order set',
	       'PANEL.US.URO'=>'Urology ultrasound order set',
	       'PANEL.VITALS'=>'Vital signs order set',
	       'PATH.PROTOCOLS'=>'Pathology protocols',
	       'PULM'=>'Pulmonary ventilator management',
	       'RAD'=>'Radiology',
	       'RESP.ATOM'=>'Respiration atomic',
	       'RESP.MOLEC'=>'Respiration molecular',
	       'RESP.TIMED.MOLEC'=>'Respiration timed molecular',
	       'SKNFLD.MOLEC'=>'Skinfold measurements molecular',
	       'TUMRRGT'=>'Tumor registry (NAACCR)',
	       'US.URO'=>'Urological ultrasound',
	       'VACCIN'=>'Vaccinations',
	       'VOLUME.MOLEC'=>'Volume (specimens) molecular',
	       'ABXBACT'=>'Antibiotic susceptibility',
	       'ALLERGY'=>'Response to antigens',
	       'BLDBK'=>'Blood bank',
	       'CELLMARK'=>'Cell surface models',
	       'CHAL'=>'Challenge tests',
	       'CHALSKIN'=>'Skin challenge tests',
	       'CHEM'=>'Chemistry',
	       'COAG'=>'Coagulation study',
	       'CYTO'=>'Cytology',
	       'DRUG/TOX'=>'Drug levels and Toxicology',
	       'DRUGDOSE'=>'Drug dose (for transmitting doses for pharmacokinetics)',
	       'FERT'=>'Fertility',
	       'HEM/BC'=>'Hematology (coagulation) and differential count',
	       'HLA'=>'HLA tissue typing antigens',
	       'MICRO'=>'Microbiology',
	       'MISC'=>'Miscellaneous',
	       'MOLPATH'=>'Molecular Pathology',
	       'MOLPATH.DEL'=>'Gene deletion',
	       'MOLPATH.MUT'=>'Gene mutation',
	       'MOLPATH.REARRANGE'=>'Gene rearrangement',
	       'MOLPATH.TRINUC'=>'Gene trinucleotide repeats',
	       'MOLPATH.TRISOMY'=>'Gene chromosome trisomy',
	       'MOLPATH.TRNLOC'=>'Gene translocation',
	       'PANEL.ABXBACT'=>'Susceptibility order set',
	       'PANEL.ALLERGY'=>'Allergy order set',
	       'PANEL.BLDBK'=>'Blood bank order set',
	       'PANEL.CELLMARK'=>'Cellmarker order sets',
	       'PANEL.CHAL'=>'Challenge order set',
	       'PANEL.CHEM'=>'Chemistry order set',
	       'PANEL.COAG'=>'Coagulation order set',
	       'PANEL.DRUG/TOX'=>'Drug levels and Toxicology order set',
	       'PANEL.HEM/BC'=>'Hematology and blood count order set',
	       'PANEL.MICRO'=>'Microbiology order set',
	       'PANEL.OBS'=>'Obstetrics order set',
	       'PANEL.SERO'=>'Serology order set',
	       'PANEL.UA'=>'Urinalysis order set',
	       'PATH'=>'Pathology',
	       'SERO'=>'Serology (antibodies and most antigens except blood bank and infectious agents)',
	       'SPEC'=>'Specimen characteristics',
	       'UA'=>'Urinalysis',
	       'ATTACH'=>'Attachment',
	       'ATTACH.AMB'=>'Ambulance claims attachment',
	       'ATTACH.CARD'=>'Cardiac attachment',
	       'ATTACH.CLINRPT'=>'Clinical report attachment',
	       'ATTACH.CPHS'=>'Childrens Preventative Health System Attachments',
	       'ATTACH.ED'=>'Emergency department attachment',
	       'ATTACH.GI'=>'Gastrointestinal attachment',
	       'ATTACH.LAB'=>'Laboratory claims attachment',
	       'ATTACH.MEDS'=>'Medication attachment',
	       'ATTACH.MODIFIER'=>'Modifier attachment',
	       'ATTACH.OBS'=>'Obstetrics attachment',
	       'ATTACH.REHAB'=>'Rehabilitation attachment',
	       'ATTACH.REHAB.ABUSE'=>'Alcohol/Substance Abuse Rehabilitation attachment',
	       'ATTACH.REHAB.CARDIAC'=>'Cardiac Rehabilitation attachment',
	       'ATTACH.REHAB.NURS'=>'Specialized Nursing attachment',
	       'ATTACH.REHAB.OT'=>'Occupational Therapy attachment',
	       'ATTACH.REHAB.PSYCH'=>'Psychiatric Rehabilitation attachment',
	       'ATTACH.REHAB.PT'=>'Physical Therapy attachment',
	       'ATTACH.REHAB.RT'=>'Respiratory Therapy attachment',
	       'ATTACH.REHAB.SOCIAL'=>'Medical Social Work attachment',
	       'ATTACH.REHAB.SPEECH'=>'Speech Therapy Rehabilitation attachment',
	       'ATTACH.RESP'=>'Respiratory attachment',
	       'SURVEY.NURSE.HHCC'=>'Home Health Care Classification Survey',
	       'SURVEY.NURSE.HIV-SSC'=>'Signs and Symptoms Checklist for Persons with HIV Survey',
	       'SURVEY.NURSE.LIV-HIV'=>'Living with HIV Survey',
	       'SURVEY.NURSE.OMAHA'=>'OMAHA Survey',
	       'SURVEY.NURSE.QAM'=>'Quality Audit Marker Survey'
	      );
  my %SYSTEM = (
		'ABS'=>'Abscess',
		'AMN'=>'Amniotic fluid',
		'AMNC'=>'Amniotic fluid cells',
		'ANAL'=>'Anus',
		'ASP'=>'Aspirate',
		'BPH'=>'Basophils',
		'BIFL'=>'Bile fluid',
		'BLDA'=>'Blood arterial',
		'BBL'=>'Blood bag',
		'BLDC'=>'Blood capillary',
		'BLDCO'=>'Blood - Cord',
		'BLDMV'=>'Blood - Mixed Venous',
		'BLDP'=>'Blood - Peripheral',
		'BPU'=>'Blood product unit',
		'BLDV'=>'Blood venous',
		'BLD.DOT'=>'Blood filter paper',
		'BONE'=>'Bone',
		'BRAIN'=>'Brain',
		'BRO'=>'Bronchial',
		'BRN'=>'Burn',
		'CALC'=>'Calculus (=Stone)',
		'CDM'=>'Cardiac muscle',
		'CNL'=>'Cannula',
		'CTP'=>'Catheter tip',
		'CSF'=>'Cerebral spinal fluid',
		'CVM'=>'Cervical mucus',
		'CVX'=>'Cervix',
		'COL'=>'Colostrum',
		'CNJT'=>'Conjunctiva',
		'CUR'=>'Curettage',
		'CRN'=>'Cornea',
		'CYST'=>'Cyst',
		'DENTIN'=>'Dentin',
		'DIAFP'=>'Peritoneal Dialysis fluid',
		'DIAF'=>'Dialysis fluid',
		'DOSE'=>'Dose med or substance',
		'DRN'=>'Drain',
		'DUFL'=>'Duodenal fluid',
		'EAR'=>'Ear',
		'EARW'=>'Ear wax (cerumen)',
		'ELT'=>'Electrode',
		'ENDC'=>'Endocardium',
		'ENDM'=>'Endometrium',
		'EOS'=>'Eosinophils',
		'RBC'=>'Erythrocytes',
		'EYE'=>'Eye',
		'EXG'=>'Exhaled gas (=breath)',
		'FIB'=>'Fibroblasts',
		'FLT'=>'Filter',
		'FIST'=>'Fistula',
		'FLU'=>'Body fluid, unsp',
		'FOOD'=>'Food sample',
		'GAS'=>'Gas',
		'GAST'=>'Gastric fluid/contents',
		'GEN'=>'Genital',
		'GENC'=>'Genital cervix',
		'GENF'=>'Genital fluid',
		'GENL'=>'Genital lochia',
		'GENM'=>'Genital Mucus',
		'GENV'=>'Genital vaginal',
		'HAR'=>'Hair',
		'IHG'=>'Inhaled Gas',
		'IT'=>'Intubation tube',
		'ISLT'=>'Isolate',
		'LAM'=>'Lamella',
		'WBC'=>'Leukocytes',
		'LN'=>'Line',
		'LNA'=>'Line arterial',
		'LNV'=>'Line venous',
		'LIQ'=>'Liquid NOS',
		'LIVER'=>'Liver',
		'LYM'=>'Lymphocytes',
		'MAC'=>'Macrophages',
		'MAR'=>'Marrow (bone)',
		'MEC'=>'Meconium',
		'MBLD'=>'Menstrual blood',
		'MLK'=>'Milk',
		'MILK'=>'Breast milk',
		'NAIL'=>'Nail',
		'NOSE'=>'Nose (nasal passage)',
		'ORH'=>'Other',
		'PAFL'=>'Pancreatic fluid',
		'PAT'=>'Patient',
		'PEN'=>'Penis',
		'PCAR'=>'Pericardial Fluid',
		'PRT'=>'Peritoneal fluid /ascites',
		'PLC'=>'Placenta',
		'PLAS'=>'Plasma',
		'PLB'=>'Plasma bag',
		'PLR'=>'Pleural fluid (thoracentesis fld)',
		'PMN'=>'Polymorphonuclear neutrophils',
		'PPP'=>'Platelet poor plasma',
		'PRP'=>'Platelet rich plasma',
		'PUS'=>'Pus',
		'SAL'=>'Saliva',
		'SMN'=>'Seminal fluid',
		'SMPLS'=>'Seminal plasma',
		'SER'=>'Serum',
		'SKN'=>'Skin',
		'SKM'=>'Skeletal muscle',
		'SPRM'=>'Spermatozoa',
		'SPT'=>'Sputum',
		'SPTC'=>'Sputum - Coughed',
		'SPTT'=>'Sputum - tracheal aspirate',
		'STL'=>'Stool = Fecal',
		'SWT'=>'Sweat',
		'SNV'=>'Synovial fluid (Joint fluid)',
		'TEAR'=>'Tears',
		'THRT'=>'Throat',
		'THRB'=>'Thrombocyte (platelet)',
		'TISS'=>'Tissue, unspecified',
		'TISG'=>'Tissue gall bladder',
		'TLGI'=>'Tissue large intestine',
		'TLNG'=>'Tissue lung',
		'TISPL'=>'Tissue placenta',
		'TSMI'=>'Tissue small intestine',
		'TISU'=>'Tissue ulcer',
		'TRAC'=>'Trachea',
		'TUB'=>'Tube, unspecified',
		'ULC'=>'Ulcer',
		'UMB'=>'Umbilical blood',
		'UMED'=>'Unknown medicine',
		'URTH'=>'Urethra',
		'UR'=>'Urine',
		'URC'=>'Urine clean catch',
		'URT'=>'Urine catheter',
		'URNS'=>'Urine sediment',
		'USUB'=>'Unknown substance',
		'VITF'=>'Vitreous Fluid',
		'VOM'=>'Vomitus',
		'BLD'=>'Whole blood',
		'BDY'=>'Whole body',
		'WAT'=>'Water',
		'WICK'=>'Wick',
		'WND'=>'Wound',
		'WNDA'=>'Wound abscess',
		'WNDE'=>'Wound exudate',
		'WNDD'=>'Wound drainage',
		'XXX'=>'To be specified in another  part of the message'
	       );
  my %METHOD = (
		'AGGL'=>'AGGLUTINATION',
		'COAG'=>'COAGULATION ASSAY (To distinguish coagulation assays based on clotting  methods)',
		'CF'=>'COMPLEMENT FIXATION',
		'CT'=>'COMPUTERIZED TOMOGRAPHY',
		'CYTOSTAIN'=>'CYTOLOGY STAIN (The staining method used for pap smears, fine needle  aspirates and other cell stains.)',
		'PROBE'=>'DNA NUCLEIC ACID PROBE',
		'ENZY'=>'ENZYMATIC ASSAY (To distinguish coagulation assays based on  enzymatic activity.)',
		'EIA'=>'ENZYME IMMUNOASSAY (Subsumes variants such as ELISA)',
		'FLOC'=>'FLOCCULATION ASSAY',
		'FC'=>'FLOW CYTOMETRY',
		'HAI'=>'HEMAGGLUTINATION INHIBITION',
		'IHA'=>'INDIRECT HEMAGGLUTINATION',
		'IB'=>'IMMUNE BLOT',
		'IF'=>'IMMUNE FLUORESCENCE (Encompasses DFA, FA)',
		'LA'=>'LATEX AGGLUTINATION',
		'LHR'=>'LEUKOCYTE HISTAMINE RELEASE',
		'MIC'=>'MINIMUM INHIBITORY CONCENTRATION (Antibiotic susceptibilities)',
		'MLC'=>'MINIMUM LETHAL CONCENTRATION (Also called MBC (minimum bactericidal  concentration))',
		'MOLGEN'=>'MOLECULAR GENETICS (General class of methods used to detect genetic attributes on a molecular basis including RFL, PCR and other methods.)',
		'NEUT'=>'NEUTRALIZATION',
		'RIA'=>'RADIOIMMUNOASSAY',
		'SBT'=>'SERUM BACTERICIDAL TITER (Determines the serum dilution that is capable of killing microorganisms.)',
		'US'=>'ULTRASOUND',
		'VC'=>'VISUAL COUNT'
	       );
  ###################  Given classtype, get list of distinct classes of test
  if ($class =~/\d/){
    $sql = qq!SELECT DISTINCT class
					FROM loinc
					WHERE classtype="$class"!;
    $sth = $dbh->prepare($sql);
    $sth->execute;
    $sth->bind_columns(\$class);
    $return = qq!<tr><td><input type="submit" name="SubmitButton" value="Pick Observation Class"</td>
						<td><select name="Test_Class" size=10>!;
    while ($sth->fetch){
      if ($CLASS{$class}){
	$return .= qq!<option value="$class">$CLASS{$class}</option>!;
      }
      else {
	$return .= qq!<option value="$class">$class</option>!;
      }
    }
    $return .= qq!</select></td></tr>!;
  }
  else {
    #################  Last step:  Given class, method type and system, get list of tests
    if ($component && $system){
      if ($component eq "empty"){$component = "";}
      $sql = qq!SELECT DISTINCT loinc_num, component, shortname
						FROM loinc
						WHERE (class="$class" AND component LIKE "$component%" AND system LIKE "$system%") ORDER by shortname ASC!;
      $sth = $dbh ->prepare($sql);
      $sth -> execute;
      $sth ->bind_columns(\($loinc_num, $component, $shortname));
      $return = qq!<tr><td><input type="submit" name="SubmitButton" value="Pick Observation"</td>
							<td><select name="Test_Ordered" size=10>!;
      if ($component eq ""){$component = "empty";}
      while ($sth->fetch){
	if ($shortname){
	  $return .= qq!<option value="$loinc_num|$problem_id|$shortname">$shortname</option>!;
	}
	else {
	  $return .= qq!<option value="$loinc_num|$problem_id|$component">$component</option>!;
	}
      }
      $return.= qq!</select></td></tr>!;
    }
    ################# Given class and component, get list of systems covered
    elsif ($component){
      if ($component eq "empty"){$component = "";}
      $sql = qq!SELECT DISTINCT system
						FROM loinc
						WHERE (class="$class" AND component LIKE "$component%") ORDER by system ASC!;
      $sth = $dbh ->prepare($sql);
      $sth -> execute;
      $sth ->bind_columns(\($system));
      $return = qq!<tr><td><input type="submit" name="SubmitButton" value="Pick System"</td>
							<td><select name="Test_System" size=10>!;
      if ($component eq ""){$component = "empty";}
      while ($sth->fetch){
	#							if ($system =~ /(.*)\.(.*)/){
	#								$system = $1;
	#								$species = "($2)";
	#							}
	if ($SYSTEM{$system}){
	  $return .= qq!<option value="$class $component $system">$SYSTEM{$system} $species</option>!;
	}
	else {
	  $return .= qq!<option value="$class $component $system">$system $species</option>!;
	}
      }
      $return.= qq!</select></td></tr>!;
    }
    ################ Given class, get list of components
    else {
      $sql = qq!SELECT DISTINCT component
						FROM loinc
						WHERE class="$class" ORDER by component ASC!;
      $sth = $dbh ->prepare($sql);
      $sth -> execute;
      $sth ->bind_columns(\($component));
      $return = qq!<tr><td><input type="submit" name="SubmitButton" value="Pick Component"</td>
							<td><select name="Test_Component" size=10>!;
      while ($sth->fetch){
	if ($component) {
	  $return .= qq!<option value="$class $component">$component</option>!;
	}
	else {
	  $return .= qq!<option value="$class empty">empty</option>!;
	}
      }
      $return.= qq!</select></td></tr>!;
    }
  }
  return $return;
}

###################################################################################
## Get Patient Information
sub Get_Patient_Info {
  my $patient_id = shift;
  my ($patient_info, $title, $fname, $lname, $DOB, $age, $sex, $month, $day, $year, $sql, $sth);
  $month = (localtime)[4] + 1;
  $day   = (localtime)[3];
  $year  = (localtime)[5];
  $year  =~ s/^(\d)/20/;
  $sql   = "SELECT title, fname, lname, DOB, sex 
FROM patient_data 
WHERE pid='".$patient_id."'";
  $sth   = $dbh->prepare($sql);
  $sth   ->execute;
  $sth   ->bind_columns(\($title, $fname, $lname, $DOB, $sex));
  while ($sth->fetch){
    $age = todays_date()-$DOB;
    $DOB =~  s/(\d*)-(\d*)-(\d*)/$2\/$3\/$1/;
    $patient_info = qq!

<table>
  <tr><td><h1 class="comp">$title $fname $lname</h1></Td>
    <td><h3>DOB: $DOB</h3></td>
      <td><h3>Age: $age</h3></td>
	<td><h3>PID: $patient_id</h3></td>
	  <td><h3>Visit Date: $month/$day/$year</h3></td></tr>
	    </table>
	      
	      !;
  }
  return $title, $fname, $lname, $DOB, $age, $sex;
}

###################################################################################
## Get Todays Problem List
## Input: Passed in by param(), $pass represents the first pass - to keep from updating meds too often.
## Output: $page, INSERTS INTO problem_list

sub Get_Todays_Problem_List {
  my ($pass, $patient_id) = @_;
  my ($page, $problem_id, $id, $concept, $code, $date_added, $active, $chronic, $year, $month, $day, $sql, $sth);
  my ($pastref, $chronicref, $ongoingref, $acuteref, $activeref);
  ################################################ Add New Problem to Problem List
  if (param('SubmitButton') eq 'Add New Problem'){
    $page .= qq!<input type="text" name="Problem_Text_Search" onBlur="shiftFocus('Problem_Text_Search')"/><br>
		<select name="Type_of_Problem">
		<option value="3">Past</option>
		<option value="2">Chronic</option>
		<option value="1">Ongoing</option>
		<option value="0">Acute</option>
		</select><br> !;
  }
  ################################################ Search for Name and ICD-9-CM code of New Problem from table icd_9_cm_concepts
  elsif (param('SubmitButton') eq 'Search for Problem'){
    $sql = "SELECT id, concept, code 
FROM icd_9_cm_concepts 
WHERE concept REGEXP '".param('Problem_Text_Search')."' 
ORDER BY code";
    $sth = $dbh->prepare($sql);
    $sth->execute;
    $sth ->bind_columns(\($id, $concept, $code));
    $page .= qq!<select name='Choose_Problem' size="20" onBlur="shiftFocus('Choose_Problem')"> !;
    while ($sth->fetch){
      $page .= qq!<option value="$id">$concept</option> !;
    }
    $page .= qq!</select><hr>!;
  }
  ################################################  Put problems into database
  else{
    if (param('Choose_Problem') && (param('SubmitButton') eq 'Choose This Problem') && ($pass == 0)){
      $sql = "INSERT INTO problem_list (patient_id, date_added, provider_id, problem_id, active, chronic) 
VALUES('".$patient_id."', '".todays_date()."', '".param('hidden_provider_id')."', '".param('Choose_Problem')."', '1', '".param('Type_of_Problem')."')";
      $sth = $dbh->prepare($sql);
      $sth->execute;
    }
    ################################################################
    ##  Get Todays Problems
    ##  Past_Problems returns a reference to arrays @past, @chronic, @ongoing, @acute.
    ##  Each array contains the following elements: $problem_id, $concept, $code, $date_added, $active, $chronic
    ($pastref, $chronicref, $ongoingref, $acuteref) = Past_Problems($patient_id);
    if (@$pastref || @$chronicref || @$ongoingref || @$acuteref){
      unless ($page_name eq 'Update Record'){
	$page .= qq!<select name='Todays_Problems' size='50' multiple='1'> !;
      } else {
	$page .= qq!<select name='Todays_Problems' size='10'> !;
      }
      my $index = 0;
      $page .= qq!<option disabled="disabled" value=""> -- Past Problems -- </option>!;
      for ($index = 0; $index<=$#$pastref; $index++){
	if (param('Todays_Problems') eq $$pastref[$index][0]){
	  $page .= qq!<option selected="selected" value="$$pastref[$index][0]" class="wrap">$$pastref[$index][1] $$pastref[$index][2] Date Added:$$pastref[$index][3] Active:$$pastref[$index][4]</option>!;
	} else {
	  $page .= qq!<option value="$$pastref[$index][0]" class="wrap">$$pastref[$index][1] $$pastref[$index][2] Date Added:$$pastref[$index][3] Active:$$pastref[$index][4]</option>!;
	}
      }
      $page .= qq!<option disabled="disabled" value=""> -- Chronic Problems -- </option>!;
      for ($index = 0; $index<=$#$chronicref; $index++){
	if (param('Todays_Problems') eq $$chronicref[$index][0]){
	  $page .= qq!<option selected="selected" value="$$chronicref[$index][0]" class="wrap">$$chronicref[$index][1] $$chronicref[$index][2] Date Added:$$chronicref[$index][3] Active:$$chronicref[$index][4]</option>!;
	} else {
	  $page .= qq!<option value="$$chronicref[$index][0]" class="wrap">$$chronicref[$index][1] $$chronicref[$index][2] Date Added:$$chronicref[$index][3] Active:$$chronicref[$index][4]</option>!;
	}
      }
      $page .= qq!<option disabled="disabled" value=""> -- Ongoing Problems -- </option>!;
      for ($index = 0; $index<=$#$ongoingref; $index++){
	if (param('Todays_Problems') eq $$ongoingref[$index][0]){
	  $page .= qq!<option selected="selected" value="$$ongoingref[$index][0]" class="wrap">$$ongoingref[$index][1] $$ongoingref[$index][2] Date Added:$$ongoingref[$index][3] Active:$$ongoingref[$index][4]</option>!;
	} else {
	  $page .= qq!<option value="$$ongoingref[$index][0]" class="wrap">$$ongoingref[$index][1] $$ongoingref[$index][2] Date Added:$$ongoingref[$index][3] Active:$$ongoingref[$index][4]</option>!;
	}
      }
      $page .= qq!<option disabled="disabled" value=""> -- Acute Problems -- </option>!;
      for ($index = 0; $index<=$#$acuteref; $index++){
	if (param('Todays_Problems') eq $$acuteref[$index][0]){
	  $page .= qq!<option selected="selected" value="$$acuteref[$index][0]" class="wrap">$$acuteref[$index][1] $$acuteref[$index][2] Date Added:$$acuteref[$index][3] Active:$$acuteref[$index][4]</option>!;
	} else {
	  $page .= qq!<option value="$$acuteref[$index][0]" class="wrap">$$acuteref[$index][1] $$acuteref[$index][2] Date Added:$$acuteref[$index][3] Active:$$acuteref[$index][4]</option>!;
	}
      }
      $page .= qq!</select><br> !;
    }
    else {
      $page .= "No past problems noted.  Please add Todays Problem(s).";
    }
    $page .= qq! !;
  }
  return $page;
}

#############################################################################################
## Form to fill out in order to produce note

sub Note_Format {
  my $patient_id = shift;
  my (@problem_id, $problem, $page, $CC, $HPI, $ROS, $FSH, $PE, $DR, $Meds, $title, $fname, $lname, $sql, $sth, @concept, @date_added, $DOB, $age, $sex);

  ###############################################  Patient Information and Chief Compaint
  @problem_id = param('Todays_Problems');
  ($title, $fname, $lname, $DOB, $age, $sex) = Get_Patient_Info($patient_id);
  $CC .= qq!<table>!;
  foreach $problem (@problem_id){
    $sql   = qq!SELECT icd_9_cm_concepts.concept, date_added 
		FROM problem_list LEFT JOIN icd_9_cm_concepts ON problem_list.problem_id=icd_9_cm_concepts.id 
		WHERE problem_list.patient_id="$patient_id" and problem_list.problem_id="$problem"! ;
    $sth = $dbh->prepare($sql);
    $sth ->execute;
    $sth ->bind_columns(\($concept[$problem], $date_added[$problem]));
    while ($sth->fetch){
      $date_added[$problem]=~ s/(\d+)-(\d+)-(\d+)/$2\/$3\/$1/;
      $CC .= qq!<tr><td>$concept[$problem] First Noted: $date_added[$problem]</td></tr>!;
    }
  }
  $CC .= qq!</table>!;
  ##############################################  HPI

  $HPI .=    qq!<table>!;
  foreach $problem (@problem_id){
    if ($concept[$problem] =~ /\[V.*/){
      $HPI .=qq!<tr><td><b>$concept[$problem]</b></td></tr>
	<tr><td>Particular Concerns</td><td><textarea name="$problem concerns" rows="2" cols="75"></textarea></td></tr>!;
    }
    else{
      $HPI .=qq!<tr><td colspan="2"><b>$concept[$problem]</b></td></tr>
	<tr><td>Location</td>
	<td><textarea name="$problem Location"  rows="2" cols="75"></textarea></td></tr>
	<tr><td>Quality</td>
	<td><textarea name="$problem Quality"  rows="2" cols="75"></textarea></td></tr>
	<tr><td>Quantity/Severity</td>
	<td><textarea name="$problem Quantity"  rows="2" cols="75"></textarea></td></tr>
	<tr><td>Timing<br> (Onset, Duration, Frequency)</td>
	<td><textarea name="$problem Timing"  rows="2" cols="75"></textarea></td></tr>
	<tr><td>Setting<br>Context</td>
	<td><textarea name="$problem Setting"  rows="2" cols="75"></textarea></td></tr>
	<tr><td>Aggravating/Relieving</td>
	<td><textarea name="$problem Aggravating Relieving"  rows="2" cols="75"></textarea></td></tr>
	<tr><td>Associated Signs and Symptoms</td>
	<td><textarea name="$problem Associated Manifestations"  rows="2" cols="75"></textarea></td></tr>
	<tr><td>Patient's Reaction<br>Effect on Life</td>
	<td><textarea name="$problem Patient Reaction" rows="2" cols="75"></textarea></td></tr>!;
    }
  }
 $HPI .= qq!</table><table>!;
  $HPI .= qq!<tr><td><input type="checkbox" name="Reviewed and summarized old patient chart">Reviewed and summarized old patient chart</td> 
<td><input type="checkbox" name="Obtained history from someone other than patient">Obtained history from someone other than patient</td></tr>
</table>!;

#################################################  Review of Systems
$ROS = qq!<table>!;
  #<tr></td><input type="submit" name="SubmitButton" value="Full Review of Systems"></td></tr>
  $ROS .= qq!<tr><td colspan="1"><b>Any Pain</b>
<Select name="Pain">
<option value=""></option>
<option value="Yes">Yes</option>
<option value="No">No</option>
</select></td>
<td colspan="1">Pain Scale
<select name="Pain Scale">
<option value="0">0</option>
<option value="1">1</option>
<option value="2">2</option>
<option value="3">3</option>
<option value="4">4</option>
<option value="5">5</option>
<option value="6">6</option>
<option value="7">7</option>
<option value="8">8</option>
<option value="9">9</option>
<option value="10">10</option>
</select></td>
<td colspan="6">Pain Location<input type=text name="Pain Location" size=20 /></td></tr>!;
  #    if (param('SubmitButton') eq 'Full Review of Systems'){

  $ROS .= qq!<tr><th>General</th><th>Skin</th><th>Head</th><th>Eyes</th><th>Ears</th></tr>
	<tr>
	<td><select name="General" multiple="multiple" default="usual state of health" size="5" >
<option value="normal">usual state of health</option>
<option value="usual weight">usual weight</option>
<option value="recent weight change">recent weight change</option>
<option value="fatigue">fatigue</option>
<option value="weakness">weakness</option>
<option value="fever">fever</option>
<option value="chills">chills</option>
<option value="night sweats">night sweats</option>
<option value="poor appetite">poor appetite</option>
<option value="insomnia">insomnia</option>
<option value=""></option>
</select></td>
<td><select name="Skin" multiple="multiple" default="normal" size="5" >
        <option value="normal">normal</option>
	<option value="rashes">rashes</option>
	<option value="lumps">lumps</option>
	<option value="sores">sores</option>
	<option value="acne">acne</option>
	<option value="itching">itching</option>
	<option value="dryness">dryness</option>
	<option value="color change">color change</option>
	<option value="moles">moles</option>
	<option value="hair changes">hair changes</option>
	<option value="nail changes">nail changes</option>
	</select></td>
	<td><select name="Head" multiple="multiple" default="normal" size="5">
<option values="normal">normal</option>
<option value="headache">headache</option>
<option value="head Injury">head injury</option>
</select></td>
<td><select name="Eyes" multiple="multiple" default="normal" size="5">
	<option value="normal">normal</option>
	<option value="double vision">double vision</option>
	<option value="blurred vision">blurred vision</option>
	<option value="eye pain">eye pain</option>
	<option value="redness">redness</option>
	<option value="excessive tearing">excessive tearing</option>
	<option value="spots">spots</option>
	<option value="glaucoma">glaucoma</option>
	<option value="cataracts">cataracts</option>
	</select></td>
	<td><select name="Ears" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="poor hearing">poor hearing</option>
<option value="ringing in ears">ringing in ears</option>
<option value="dizziness">dizziness</option>
<option value="infection">infection</option>
<option value="earaches">earaches</option>
<option value="discharge">discharge</option>
</select></td>
</tr>
<tr><th>Nose<br>Sinuses</th><th>Mouth<br>Throat</th><th>Neck</th><th>Breasts</th><th>Respiratory</th></tr>!;
	$ROS .= qq!<tr>
<td><select name="Nose and Sinuses" multiple="multiple" default="normal" size="5">
	<option value="normal">normal</option>
	<option value="frequent colds">frequent colds</option>
	<option value="nasal discharge">nasal discharge</option>
	<option value="nasal congestion">nasal congestion</option>
	<option value="nasal itching">nasal itching</option>
	<option value="hay fever">hay fever</option>
	<option value="epistaxis">epistaxis</option>
	<option value="sinus problems">sinus problems</option>
	</select></td>
	<td><select name="Mouth and Throat" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="sore tongue">sore tongue</option>
<option value="bleeding gums">bleeding gums</option>
<option value="tooth pain">tooth pain</option>
<option value="dry mouth">dry mouth</option>
<option value="sore throat">sore throat</option>
<option value="hoarseness">hoarseness</option>
<option value="frequent sore throat">frequent sore throat</option>
</select></td>
<td><select name="Neck" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="swollen lymph nodes">LAN</option>
<option value="lumps">lumps</option>
<option value="goiter">goiter</option>
<option value="stiff neck">stiff neck</option>
</select></td>
<td><select name="Breasts" multiple="multiple" default="normal" size="5">
	<option value="normal">normal</option>
	<option value="lump in right breast">lump R</option>
	<option value="lump in left breast">lump L</option>
	<option value="pain in right breast">pain R</option>
	<option value="pain in left breast">pain L</option>
	<option value="nipple discharge from right breast">nipple disch R</option>
	<option value="nipple discharge from left breast">nipple disch L</option>
	</select></td>
	<td><select name="Respiratory" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="cough">cough</option>
<option value="shortness of breath">shortness of breath</option>
<option value="asthma">asthma</option>
<option value="pain on breathing">pain on breathing</option>
<option value="wheezing">wheezing</option>
<option value="sputum production">sputum production</option>
<option value="hemoptysis">hemoptysis</option>
</select></td></tr>
<th>Cardiac</th><th>GI</th><th>Urinary</th>!;
if ($sex eq 'M'){$ROS .="<th>Male Genital</th><th>Peripheral Vascular</th></tr>";}
	if ($sex eq 'F'){$ROS .="<th>Female Genital</th><th>Peripheral Vascular</th></tr>";}
$ROS .= qq!<td><select name="Cardiac" multiple="multiple" default="normal" size="5">
	<option value="normal">normal</option>
	<option value="irregular heart beat">irregular heart beat</option>
	<option value="chest pains">chest pains</option>
	<option value="shortness of breath">shortness of breath</option>
	<option value="orthopnea">orthopnea</option>
	<option value="paroxysmal nocturnal dyspnea">PND</option>
	<option value="wheezing">wheezing</option>
	<option value="high blood pressure">high blood pressure</option>
	<option value="swelling in leg">swelling in leg</option>
	<option value="poor circulation">poor circulation</option>
	</select></td>
	<td><select name="GI" multiple="multiple" default="normal" size="5" >
<option value="normal">normal</option>
<option value="pain on swallowing">pain on swallow</option>
<option value="heartburn">heartburn</option>
<option value="indigestion">indigestion</option>
<option value="decrease appetite">decreased appetite</option>
<option value="nausea">nausea</option>
<option value="vomiting">vomiting</option>
<option value="hematemesis">hematemesis</option>
<option value="epigastric pains">epigastric pains</option>
<option value="right upper quadrant pain">RUQ pain</option>
<option value="left upper quadrant pain">LUQ pain</option>
<option value="right lower quadrant pain">RLQ pain</option>
<option value="left lower quadrant pain">LLQ pain</option>
<option value="excessive gas">excessive gas</option>
<option value="change in bowel habits">change bowel habits</options>
<option value="diarrhea">diarrhea</option>
<option value="constipation">constipation</option>
<option value="bright red blood per rectum">BRBPR</option>
<option value="melena">melena</option>
<option value="hematochezia">hematochezia</option>
<option value="jaundice">jaundice</option>
</select></td>
<td><select  name="GU"  multiple="multiple" default="normal" size="5" > 
	<option value="normal">normal</option>
	<option value="polyuria">polyuria</option>
	<option value="nocturia">nocturia</option>
	<option value="kidney stones">kidney stones</option>
	<option value="burning with urination">burning urine</option>
	<option value="pain with urination">pain with urination</option>
	<option value="hematuria">hematuria</option>
	<option value="discharge from urethra">discharge</option>
	<option value="urinary infections">urinary infections</option>
	<option value="urinary urgency">urinary urgency</option>
	<option value="urinary hesitancy">urinary hesitancy</option>
	<option value="urinary incontinence">urinary incontinence</option>
	<option value="reduced force">reduced force</option>
	<option value="dribbling">dribbling</option>
	</select></td>!;
	if ($sex eq 'M'){
$ROS .= qq!<td><select name="Male Genital" multiple="multiple" default="normal" size="5" >
	<option value="normal">normal</option>
	<option value="nernia">hernia</option>
	<option value="discharge from penis">discharge from penis</option>
	<option value="sore on penis">sore on penis</option>
	<option value="testicular pain">testicular pain</option>
	<option value="testicular mass">testicular mass</option>
	</select></td>!;
	}
if ($sex eq 'F'){
	$ROS .= qq!<td><select name="Female Genital" multiple="multiple" default="normal" size="5" >
<option value="normal">normal</option>
<option value="irregular menses">irregular menses</option>
<option value="amenorrhea">amenorrhea</option>
<option value="bleeding between periods">bleeding between periods</option>
<option value="prolonged period">prolonged period</option>
<option value="premenstrual tension">premenstrual tension</option>
<option value="menopausal symptoms">menopausal symptoms</option>
<option value="post-menopausal bleeding">post-menopausal bleeding</option>
<option value="vaginal discharge">vaginal discharge</option>
<option value="vaginal itching">vaginal itching</option>
<option value="sores in vagina">sores in vagina</option>
<option value="lumps in groin">lumps in groin</option>
<option value="dyspareunia">dyspareunia</option>
</select></td>!;
}
$ROS .= qq!<td><select name="Peripheral Vascular" multiple="multiple" default="normal" size="5" >
	<option value="normal">normal</option>
	<option value="intermittent claudication">intermit claud</option>
	<option value="leg cramps">leg cramps</option>
	<option value="varicose veins">varicose veins</option>
	<option value="swelling in left leg">swell in l leg</option>
	<option value="swelling in right leg">swell in r leg</option>
	<option value="cold feet">cold feet</option>
	</select></td></tr>!;
$ROS .= qq!<tr><th>Neurologic</th><th>Musc-Skel</th><th>Endo</th><th>Heme</th><th>Psyche</th><th></th></tr>
<tr>
	<td><select name="Neurological" multiple="multiple" default="normal" size="5" >
<option value="normal">normal</option>
<option value="loss of consciousness">loss of consciousness</option>
<option value="syncope">syncope</option>
<option value="seizure">seizure</option>
<option value="light headed">light headed</option>
<option value="local weakness">local weakness</option>
<option value="paralysis">paralysis</option>
<option value="numbness">numbness</option>
<option value="tingling">tingling</option>
<option value="tremor">tremor</option>
<option value="restless legs">restless legs</option>
</select></td>
<td><select name="Musc-Skel"  multiple="multiple" default="normal" size="5" >
	<option value="normal">normal</option>
	<option value="muscle pain">muscle pain</option>
	<option value="rheumotoid arthritis">rheumotoid arthritis</option>
	<option value="swollen joints">swollen joints</option>
	<option value="stiff joints">stiff joints</option>
	<option value="broken bones">broken bones</option>
	<option value="neck problems">neck problems</option>
	<option value="back problems">back problems</option>
	<option value="scoliosis">scoliosis</option>
	<option value="shoulder problems">shoulder problems</option>
	<option value="elbow problems">elbow problems</option>
	<option value="wrist problems">wrist problems</option>
	<option value="hand problems">hand problems</option>
	<option value="hip problems">hip problems</option>
	<option value="knee problems">knee problems</option>
	<option value="ankle problems">ankle problems</option>
	<option value="foot problems">foot problems</option>
	</select></td>
	<td><select name="Endo" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="insulin dependent diabetes">diabetes</option>
<option value="polyuria">polyuria</option>
<option value="cold intolerence">cold intolerence</option>
<option value="heat intolerence">heat intolerence</option>
<option value="excessive thirst">excessive thirst</option>
<option value="excessive sweating">excessive sweating</option>
<option value="excessive hunger">excessive hunger</option>
</select></td>
<td><select name="Heme" multiple="multiple" default="normal" size="5" >
	<option value="normal">normal</option>
	<option value="easy bleeding">easy bleeding</option>
	<option value="easy bruising">easy bruising</option>
	<option value="anemia">anemia</option>
	<option value="diziness with standing">diziness with standing</option>
	</select></td>
	<td><select name="Psych" multiple="multiple" default="normal" size="5" >
<option value="normal">normal</option>
<option value="nervousness">nervousness</option>
<option value="memory problem">memory problem</option>
<option value="mood problem">mood problem</option>
<option value="depressed">depressed</option>
<option value="sleep disturbance">sleep disturbance</option>
</select></td><td></td><td></td></tr>!;
#}
$ROS .= qq!<tr><th colspan="1" >Other Pertinent Symptoms</th>
<td colspan="7"><input type=text name="Other Symptoms" size="100" /></td></tr>
</table>!;

  ############################################################ Add Past/Family/Social History
  my $last_social_history;
  $sql = qq!SELECT last_social_history 
FROM history_data 
WHERE pid="$patient_id"!;
  $sth = $dbh->prepare($sql);
  $sth ->execute;
  $sth ->bind_columns(\$last_social_history);
  $FSH =  qq!<table class="Container">!;
  if ($sth->fetch){
    $FSH .= qq!<tr><td>Unchanged from visit date $last_social_history</td></tr>!;
  }
  $FSH .= qq!
<tr><td><label for="Nutritional Needs">Nutritional Needs</label>
<select name='Nutritional Needs' size="1">
<option  value=""></option>
<option value="Yes">Yes</option>
<option value="No">No</option>
</select></td>
<td><label for="Psychological Needs">Psychological Needs</label>
<select name='Psychological Needs' size="1">
<option  value=""></option>
<option value="Yes">Yes</option>
<option value="No">No</option>
</select></td>
<td><label for="Educational Needs">Educational Needs</label>
<select name='Educational Needs' size="1">
<option  value=""></option>
<option value="Yes">Yes</option>
<option value="No">No</option>
</select></td></tr>!;

  my (@chronic, @ongoing, @acute, @past, $c);

  ##### Get Past History
  my ($id, $coffee, $alcohol, $drug_use, $sleep_patterns, $exercise_patterns, $std, $reproduction, $sexual_function, $self_breast_exam, $self_testicle_exam, $seatbelt_use, $counseling, $hazardous_activities, $last_breast_exam, $last_mammogram, $last_gynocological_exam, $last_psa, $last_prostate_exam, $last_physical_exam, $last_sigmoidoscopy_colonoscopy, $last_fecal_occult_blood, $last_ppd, $last_bone_density, $history_mother, $history_father, $history_siblings, $history_offspring, $history_spouse, $relatives_cancer, $relatives_tuberculosis, $relatives_diabetes, $relatives_hypertension, $relatives_heart_problems, $relatives_stroke, $relatives_epilepsy, $relatives_mental_illness, $relatives_suicide, $date, $pid, $name_1, $value_1, $name_2, $value_2, $additional_history, $concept, $date_added, $code, $active, $chronic);
  $sql = qq!SELECT id, coffee, alcohol, drug_use, sleep_patterns, exercise_patterns, std, reproduction, sexual_function, self_breast_exam, self_testicle_exam, seatbelt_use, counseling, hazardous_activities, last_social_history, last_breast_exam, last_mammogram, last_gynocological_exam, last_psa, last_prostate_exam, last_physical_exam, last_sigmoidoscopy_colonoscopy, last_fecal_occult_blood, last_ppd, last_bone_density, history_mother, history_father, history_siblings, history_offspring, history_spouse, relatives_cancer, relatives_tuberculosis, relatives_diabetes, relatives_hypertension, relatives_heart_problems, relatives_stroke, relatives_epilepsy, relatives_mental_illness, relatives_suicide, date, pid, name_1, value_1, name_2, value_2, additional_history 
FROM history_data
WHERE pid="$patient_id"!;
  $sth = $dbh->prepare($sql);
  $sth ->execute;
  $sth ->bind_columns(\($id, $coffee, $alcohol, $drug_use, $sleep_patterns, $exercise_patterns, $std, $reproduction, $sexual_function, $self_breast_exam, $self_testicle_exam, $seatbelt_use, $counseling, $hazardous_activities, $last_social_history, $last_breast_exam, $last_mammogram, $last_gynocological_exam, $last_psa, $last_prostate_exam, $last_physical_exam, $last_sigmoidoscopy_colonoscopy, $last_fecal_occult_blood, $last_ppd, $last_bone_density, $history_mother, $history_father, $history_siblings, $history_offspring, $history_spouse, $relatives_cancer, $relatives_tuberculosis, $relatives_diabetes, $relatives_hypertension, $relatives_heart_problems, $relatives_stroke, $relatives_epilepsy, $relatives_mental_illness, $relatives_suicide, $date, $pid, $name_1, $value_1, $name_2, $value_2, $additional_history));
  $sth->fetch;

  $sql   = qq!SELECT concept, code, date_added, active, chronic 
FROM problem_list LEFT JOIN icd_9_cm_concepts ON problem_list.problem_id=icd_9_cm_concepts.id 
WHERE patient_id="$patient_id"!;
  $sth = $dbh->prepare($sql);
  $sth ->execute;
  $sth ->bind_columns(\($concept, $code, $date_added, $active, $chronic));
  while ($sth->fetch){
    $concept =~s/(.*)\[.*\]/$1/;
    if ($chronic == 3){
      push(@past, [$concept, $code, $date_added]);
    }
    if ($chronic == 2){
      push(@chronic, [$concept, $code, $date_added]);
    }
    if ($chronic == 1){
      push(@ongoing, [$concept, $code, $date_added]);
    }
    if ($chronic == 0){
      push(@acute, [$concept, $code, $date_added]);
    }
  }

  if (@past || @chronic || @ongoing){
    $c=1;
    if (@past){$c=$c+$#past;}
    if (@chronic){$c=$c+$#chronic;}
    if (@ongoing){$c=$c+$#ongoing;}
    $FSH .= qq!<tr><td colspan="8"><fieldset><legend>Past Medical History</legend><table>!;
    my $index = 0;
    $FSH .= qq!<tr><td>Past Problems</td><td></td><td></td><td></td></tr>!;
    for ($index = 0; $index<=$#past; $index++){
      $FSH .= qq!<tr><td></td><td>$past[$index][0]</td><td>$past[$index][1]</td><td>$past[$index][2]</td><td>$past[$index][3]</td></tr>!;
    }
    $FSH .= qq!<tr><td>Chronic Problems</td><td></td><td></td><td></td></tr>!;
    for ($index = 0; $index<=$#chronic; $index++){
      $FSH .= qq!<tr><td></td><td>$chronic[$index][0]</td><td>$chronic[$index][1]</td><td>$chronic[$index][2]</td><td>$chronic[$index][3]</td></tr>!;
    }
    $FSH .= qq!<tr><td>Ongoing Problems</td><td></td><td></td><td></td></tr>!;
    for ($index = 0; $index<=$#ongoing; $index++){
      $FSH .= qq!<tr><td></td><td>$ongoing[$index][0]</td><td>$ongoing[$index][1]</td><td>$ongoing[$index][2]</td><td>$ongoing[$index][3]</td></tr>!;
    }
    $FSH .= qq!</table></fieldset></td></tr>!;
  } else {$FSH .= qq!<tr><th>No significant Past Medical History noted.</th><td colspan=2><input type=text name="Past Medical History" /></td></tr>!;}

  ##### Social History
  $FSH .= qq!<tr><td colspan="8"><fieldset><legend>Social History</legend><table>!;
$FSH .= qq!<tr><th align=RIGHT>Coffee</th>!;$FSH.=qq!<td><input type=text name="coffee"!; if ($coffee ){$FSH .= qq! value="$coffee"!;} $FSH.=qq! /></td>!;
$FSH .= qq!<th align=RIGHT>Alcohol</th>!;$FSH .= qq!<td><input type=text name="alcohol"!; if ( $alcohol ){$FSH.=qq! value="$alcohol"!;} $FSH.=qq! /></td>!;
$FSH .= qq!<th align=RIGHT>Drugs</th>!;$FSH.=qq!<td><input type=text name="drug"!; if ( $drug_use ){$FSH .= qq! value="$drug_use"!;} $FSH .=qq! /></td>!;
$FSH .= qq!<th align=RIGHT>Sleep</th>!; $FSH.=qq!<td><input type=text name="sleep_patterns"!;if ( $sleep_patterns ){$FSH .= qq! value="$sleep_patterns"!;}  $FSH .=qq! /></td></tr>!;
$FSH .= qq!<tr><th align=RIGHT>Exercise</th>!; $FSH .= qq!<td><input type=text name="exercise_patterns"!; if ( $exercise_patterns ){$FSH.=qq! value="$exercise_patterns"!;} $FSH.=qq! /></td>!;
$FSH .= qq!<th align=RIGHT>STD</th>!; $FSH .= qq!<td><input type=text name="std"!; if ( $std ){$FSH.=qq! value="$std"!;}  $FSH.=qq! /></td>!;
$FSH .= qq!<th align=RIGHT>Reproduction</th>!; $FSH .= qq!<td><input type=text name="reproduction"!; if ( $reproduction ){$FSH.=qq! value="$reproduction"!;}  $FSH.=qq! /></td>!;
$FSH .= qq!<th align=RIGHT>Sex</th>!; $FSH .= qq!<td><input type=text name="sexual_function"!; if ( $sexual_function ){$FSH .=qq! value="$sexual_function"!;} $FSH.=qq! /></td></tr>!;
if($sex eq 'F'){
  $FSH .= qq!<tr><th>Self Breast Exam</th><td><input type=text name="self_breast_exam"!;
    if ( $self_breast_exam ){$FSH.=qq!value="$self_breast_exam"!;}
$FSH .= qq! /></td>!;
}
if($sex eq'M'){
  $FSH .= qq!<tr><th>Self Testicle Exam</th><td><input type=text name="self_testicle_exam"!;
if ( $self_testicle_exam ){$FSH.=qq!value="$self_testicle_exam"!;}
    $FSH .= qq! /></td>!;
}
  $FSH .= qq!<th align=RIGHT>Seatbelt</th>!;$FSH .= qq!<td><input type=text name="seatbelt_use"!; if ( $seatbelt_use ){$FSH .=qq! value="$seatbelt_use"!;} $FSH.=qq! /></td>!;
  $FSH .= qq!<th align=RIGHT>Counseling</th>!;$FSH .= qq!<td><input type=text name="counseling"!; if ( $counseling ){$FSH.=qq! value="$counseling"!;} $FSH.=qq! /></td>!;
  $FSH .= qq!<th align=RIGHT>Risks</th>!; $FSH .= qq!<td><input type=text name="hazardous_activities"!; if( $hazardous_activities ){$FSH.=qq! value="$hazardous_activities"!;} $FSH.=qq! /></td></tr>!;
  $FSH .= qq!</table></fieldset></td></tr>!;

  ##### Family History
  $FSH .= qq!<tr><td colspan="8"><fieldset><legend>Family History</legend><table>!;
  $FSH .= qq!<tr><th align=RIGHT>Mother</th>!;
$FSH .=qq!<td><input type=text name="history_mother"!; if ( $history_mother ){$FSH.=qq! value="$history_mother"!;} $FSH.=qq! /></td>!;
$FSH .= qq!<th align=RIGHT>Father</th>!;
$FSH .=qq!<td><input type=text name="history_father"!; if ( $history_father ){$FSH.=qq! value="$history_father"!;} $FSH.=qq! /></td>!;
$FSH .= qq!<th align=RIGHT>Siblings</th>!;
$FSH .=qq!<td><input type=text name="history_siblings"!; if ( $history_siblings ){$FSH.=qq! value="$history_siblings"!;} $FSH.=qq! /></td>!;
$FSH .= qq!<th align=RIGHT>Offspring</th>!;
$FSH .=qq!<td><input type=text name="history_offspring"!; if ( $history_offspring ){$FSH.=qq! value="$history_offspring:!;} $FSH.=qq! /></td></tr>!;
$FSH .= qq!<tr><th align=RIGHT>Spouse</th>!;
$FSH .=qq!<td><input type=text name="history_spouse"!; if ( $history_spouse ){$FSH.=qq! value="$history_spouse"!;} $FSH.=qq! /></td>!;
$FSH .= qq!<th align=RIGHT>Cancer</th>!;
$FSH .=qq!<td><input type=text name="relatives_cancer"!; if ( $relatives_cancer ){$FSH.=qq! value="$relatives_cancer"!;} $FSH.=qq! /></td>!;
$FSH .= qq!<th align=RIGHT>TB</th>!;
$FSH .=qq!<td><input type=text name="relatives_tuberculosis"!; if ( $relatives_tuberculosis ){$FSH.=qq! value="$relatives_tuberculosis"!;} $FSH.=qq! /></td>!;
$FSH .= qq!<th align=RIGHT>Diabetes</th>!;
$FSH .=qq!<td><input type=text name="relatives_diabetes"!; if ( $relatives_diabetes ){$FSH.=qq! value="$relatives_diabetes"!;} $FSH.=qq! /></td></tr>!;
$FSH .= qq!<tr><th align=RIGHT>HTN</th>!;
$FSH .=qq!<td><input type=text name="relatives_hypertension"!; if ( $relatives_hypertension ){$FSH.=qq! value="$relatives_hypertension"!;} $FSH .=qq! /></td>!;
$FSH .= qq!<th align=RIGHT>CAD</th>!;
$FSH .=qq!<td><input type=text name="relatives_heart_problems"!; if ( $relatives_heart_problems ){$FSH.=qq! value="$relatives_heart_problems"!;} $FSH.=qq! /></td>!;
$FSH .= qq!<th align=RIGHT>Stroke</th>!;
$FSH .=qq!<td><input type=text name="relatives_stroke"!; if ( $relatives_stroke ){$FSH.=qq! value="$relatives_stroke"!;} $FSH.=qq! /></td>!;
$FSH .= qq!<th align=RIGHT>Epilepsy</th>!;
$FSH .=qq!<td><input type=text name="relatives_epilepsy"!; if ( $relatives_epilepsy ){$FSH.=qq! value="$relatives_epilepsy"!;} $FSH.=qq! /></td></tr>!;
$FSH .= qq!<tr><th align=RIGHT>Psych</th>!;
$FSH .=qq!<td><input type=text name="relatives_mental_illness"!; if ( $relatives_mental_illness ){$FSH.=qq! value="$relatives_mental_illness"!;} $FSH.=qq! /></td>!;
$FSH .= qq!<th align=RIGHT>Suicide</th>!;
$FSH .=qq!<td><input type=text name="relatives_suicide"!; if ( $relatives_suicide ){$FSH.=qq! value="$relatives_suicide"!;} $FSH.=qq! /></td></tr>!;
$FSH .= qq!</table></fieldset></td></tr>!;

#####  Medications
$FSH .= qq!<tr><td colspan="8"><fieldset><legend>Medications</legend><table>!;
my ($trade_name, $strength, $unit, $route, $frequency);
$sql = qq!SELECT prescriptions.id, drug, dosage, unit, route_name, frequency 
FROM prescriptions LEFT JOIN tblroute ON tblroute.route_code=prescriptions.route 
WHERE patient_id="$patient_id"!;
$sth = $dbh->prepare($sql);
$sth ->execute;
$sth ->bind_columns(\($id, $trade_name, $strength, $unit, $route, $frequency));
$c = $sth->rows;
$FSH .= qq!<tr><td colspan="8">!;
while ($sth->fetch){
    $route =~ s/\s{2,200}(\w*)\s{2,200}/$1/;
    $frequency =~ s/\s{2,200}(\w*)\s{2,200}/$1/;
    $FSH .= qq!$trade_name $strength $unit $route $frequency<br>!;
}
substr($FSH, -4)=qq!</td></tr>!;
$FSH .= qq!</table></fieldset></td></tr></table>!;

###########################################  Physical Exam
$PE .=   qq!<table>
<tr><td>BP<input type=text name="Blood Pressure" size="7" /></td>
<td>HR<input type=text name="Heart Rate" size ="3" /></td>
<td>RR<input type=text name="Respiratory Rate" size="2" /></td>
<td>Temp<input type=text name="Temperature" size="3" /></td>
<td>FS<input type=text name="Blood Glucose" size="3" /></td>
<td>Ht<input type=text name="Height" size="5" /></td>
<td>Wt<input type=text name="Weight" size="3" /></td></tr>!;
  if ($sex eq 'M'){
    $PE .= qq!<tr><input type='button' name='x' value='normal male full exam with prostate exam' onclick='normalMaleFullwithProstate();' />!;
    $PE .= qq!<input type='button' name='x' value='normal male full exam without prostate exam' onclick='normalMaleFullwithoutProstate();' />!;
  }
  if ($sex eq 'F'){
    $PE .= qq!<tr><input type='button' name='x' value='normal female full exam with GYN exam' onclick='normalFemaleFullwithGYN();' />!;
    $PE .= qq!<input type='button' name='x' value='normal fremale full exam without GYN exam' onclick='normalFemaleFullwithoutGYN();' />!;
  }
$PE .= qq!<input type='button' name='y' value='normal abbreviated exam' onclick='normalAbbrev();' /></td></tr>
<tr><th>General</th><th>Skin</th><th>Eye</th><th>Ear</th><th>Nose</th></tr>
<tr><td><select name="General_Exam" multiple="multiple" default="normal" size="5" ID="general_exam">
<option value="well nourished and groomed">Well nourished,groomed</option>
<option value="ambulatory">Ambulatory</option>
<option value="no apparent distress">NAD</option>
<option value="no weight loss">No weight loss</option>
</select></td>
<td><select name="Skin Exam" multiple="multiple" default="normal" size="5" ID="skin_exam">
<option value="normal">normal</option>
<option value="no rash">No Rash</option>
<option value="no lesions">No Lesions</option>
<option value="no suspicious moles">No Suspic Moles</option>
</select></td>
<td><select name="Eye Exam" multiple="multiple" default="normal" size="5" ID="eye_exam">
<option value="normal">normal</option>
<option value="pupils equal, round, reactive to light and accomodation">PERRLA</option>
<option value="no hematorrhages or exudates in fundi">No H,E in Fundi</option>
</select></td>
<td><select name="Ear Exam" multiple="multiple" default="normal" size="5" ID="ear_exam">
<option value="normal">normal</option>
<option value="tympanic membrane intact">TM Intact</option>
<option value="no erythema">No Eryth</option>
<option value="Rinne normal (AC>BC)">Norm Rinne</option>
<option value="Weber midline">Weber mid</option>
</select></td>
<td><select name="Nose Exam" multiple="multiple" default="normal" size="5" ID="nose_exam">
<option value="normal">normal</option>
<option value="mucosa pink">Mucosa pink</option>
<option value="septum midline">Septum mid</option>
<option value="no sinus tenderness">No sinus tender</options>
</select></td>
</tr>
<tr><td><input type=text name="General Exam Text" size="20" /></td>
<td><input type=text name="Skin Exam Text" size="20" /></td>
<td><input type=text name="Eye Exam Text" size="20" /></td>
<td><input type=text name="Ear Exam Text" size="20" /></td>
<td><input type=text name="Nose Exam Text" size="20" /></td>
</tr>
<tr><th>Mouth</th><th>Neck</th><th>Thyroid</th><th>Lymph Node</th><th>Chest</th></tr>
<tr>
<td><select name="Mouth Exam" multiple="multiple" default="normal" size="5" ID="mouth_exam">
<option value="normal">normal</option>
<option value="mucosa pink">Mucosa pink</option>
<option value="no dental carries">no carries</option>
<option value="no lesions">no lesions</option>
<option value=""></option>
</select></td>
<td><select name="Neck Exam" multiple="multiple" default="normal" size="5" ID="neck_exam">
<option value="normal">normal</option>
<option value="no erythema">no eryth</option>
<option value="no exudates">no exud</option>
<option value="no jugular venous distension">no JVD</option>
<option value="no palpable lymph nodes">no palp LN</option>
<option value="trachea midline">trach mid</option>
<option value="no bruits">no bruits</option>
</select></td>
<td><select name="Thyroid Exam" multiple="multiple" default="normal" size="5" ID="thyroid_exam">
<option value="normal">normal</option>
<option value="no thyromegaly">no thyromegaly</option>
<option value="no thyroid nodules">no thyroid nodules</option>
</select></td>
<td><select name="Lymph Node Exam" multiple="multiple" default="normal" size="5" ID="lymph_node_exam">
<option value="no submandibular lymph nodes">no Subman</option>
<option value="no cervical lymph nodes">no Cerv</option>
<option value="no supraclavicular lymph nodes">no Superclav</option>
<option value="no axillary lymph nodes">no axil</option>
<option value="no epitrochlear lymph nodes">no epitroch</option>
<option value="no hepatomegaly">no hepat</option>
<option value="no splenomegaly">no spleno</option>
<option value="no inguinal lymph nodes">no inguin</option>
</select></td>
<td><select name="Chest Exam" multiple="multiple" default="normal" size="5" ID="chest_exam">
<option value="normal">normal</option>
<option value="thorax symmetrical">thorax symmetrical</option>
<option value="ribs not tender">no tender ribs</option>
<option value="no costophrenic angle tenderness">no cva</option>
<option value=""></option>
</select></td>
</tr>
<tr>
<td><input type=text name="Mouth Exam Text" size="20" /></td>
<td><input type=text name="Neck Exam Text" size="20" /></td>
<td><input type=text name="Thyroid Exam Text" size="20" /></td>
<td><input type=text name="Lymph Node Exam Text" size="20" /></td>
<td><input type=text name="Chest Exam Text" size="20" /></td>
</tr>
<tr><th>Lungs</th><th>Heart</th><th>Breasts</th><th>Abdomen</th><th>Rectal</th></tr>
<tr>
<td><select name="Lungs Exam" multiple="multiple" default="normal" size="5" ID="lungs_exam">
<option value="normal">normal</option>
<option value="clear to auscultation">cta</option>
<option value="normal fremitus">normal fremitus</option>
<option value="no crackles">no crackles</option>
<option value="no wheezes">no wheezes</option>
<option value="no stridor">no stridor</option>
<option value="no pleural rub">no rub</option>
</select></td>
<td><select name="Heart Exam" multiple="multiple" default="normal" size="5" ID="heart_exam">
<option value="normal">normal</option>
<option value="regular rate and rhythm">rrr</option>
<option value="no murmurs, rubs or gallops">no mrg</option>
<option value="apical impulse in fifth intercostal space at mid-clavicular line">nl impulse</option>
<option value=""></option>
<option value=""></option>
</select></td>
<td><select name="Breasts Exam" multiple="multiple" default="normal" size="5" ID="breasts_exam">
<option value="normal">normal</option>
<option value="no edema">no edema</option>
<option value="no skin dimpling">no dimpl</option>
<option value="no nipple retraction">no nipl retr</option>
<option value="bilaterally symmetrical">sym</option>
<option value="no nipple discharge">no disch</option>
</select></td>
<td><select name="Abdomen Exam" multiple="multiple" default="normal" size="5" ID="abdomen_exam">
<option value="normal">normal</option>
<option value="no tenderness">nontender</option>
<option value="no scars">no scars</option>
<option value="no striae">no striae</option>
<option value="no dilated veins">veins nl</option>
<option value="normal countour">nl contour</option>
<option value="normal aortic pulsations">nl aort puls</option>
<option value="normal bowel sounds">nl sounds</option>
<option value="no hepatomegaly">no hepatomeg</option>
<option value="no splenomegaly">no splenomeg</option>
<option value="no shifting dullness">no shift dull</option>
<option value="no umbilical, ventral, or inguinal hernias">no hernia</option>
</select></td>
<td><select name="Rectal Exam" multiple="multiple" default="normal" size="5" ID="rectal_exam">
<option value="normal">Normal</option>
<option value="no masses">no mass</option>
<option value="stool guiac negative">guiac neg</option>
<option value="no fissures">no fissures</option>
<option value="no hemarrhoids">no hemarrhoids</option>
<option value="no fistulas">no fistulas</option>
<option value="no splenomegaly">no spleno</option>
</select></td>
</tr>
<tr>
<td><input type=text name="Lungs Exam Text" size="20" /></td>
<td><input type=text name="Heart Exam Text" size="20" /></td>
<td><input type=text name="Breast Exam Text" size="20" /></td>
<td><input type=text name="Abdomen Exam Text" size="20" /></td>
<td><input type=text name="Rectal Exam Text" size="20" /></td>
</tr>!;
if ($sex eq 'M'){$PE .="<th>Prostate</th><th>Testes<br>Penis</th>";}
if ($sex eq 'F'){$PE .="<th>External Female Genital</th><th>Speculum</th><th>Internal</th>";}
$PE .= qq!<th>Extremities</th><th>Pulses</th><th>Neurologic</th></tr>!;
if ($sex eq 'M'){
  $PE .=     qq!<tr><td><select name="Prostate Exam" multiple="multiple" default="normal" size="5" ID="prostate_exam">
<option value="normal">normal</option>
<option value="no mass">no mass</option>
<option value="no enlargement">no enlarge</option>
<option value="no tenderness">no tender</option>
</select></td>
<td><select name="Testes, Penis Exam" multiple="multiple" default="normal" size="5" ID="testes_penis_exam">
<option value="normal">normal</option>
<option value="no masses">no mass</option>
<option value="no lesions">no lesions</option>
<option value="no discharge">no disch</option>
<option value="no testicular nodules">no test nod</option>
<option value="no hernia">no hernia</option>
</select></td>!;
}
if ($sex eq 'F'){
    $PE .=     qq!<tr><td><select name=External Female Genital" Exam" multiple="multiple" default="normal" size="5" ID="external_female_genital_exam">
<option value="normal">normal</option>
<option value="no inflamation">no infl</option>
<option value="no ulceration">no ulcer</option>
<option value="no nodules">no nodule</option>
<option value=""></option>
</select></td>
<td><select name="Speculum Exam" multiple="multiple" default="normal" size="5" ID="speculum_exam">
<option value="normal">normal</option>
<option value="no lesions on cervix">no lesions</option>
<option value="no discharge">no disch</option>
</select></td>
<td><select name="Internal Exam" multiple="multiple" default="normal" size="5" ID="internal_exam">
<option value="normal">normal</option>
<option value="uterus not enlarged">ut not large</option>
<option value="normal ad nexa">neg adnexa</option>
</select></td>!;
}
$PE .=qq!<td><select name="Extremities Exam" multiple="multiple" default="normal" size="5" ID="extremities_exam">
<option value="normal">normal</option>
<option value="no edema">no edema</option>
<option value="no clubbing">no club</option>
<option value="no cyanosis">no cyan</option>
</select></td>
<td><select name="Pulses Exam" multiple default="normal" size="5" ID="pulses_exam">
<option value="normal">normal</option>
<option value="normal carotid bilaterally">nl carot</option>
<option value="normal femoral bilaterally">nl fem</option>
<option value="normal brachial bilaterally">nl brach</option>
<option value="normal radial bilaterally">nl rad</option>
<option value="normal dorsalis pedis bilaterally">nl dp</option>
<option value="normal posterior tibial bilaterally">nl pt</option>
</select></td>
<td><select name="Neurologic Exam" multiple default="normal" size="5" ID="neurologic_exam">
<option value="normal">normal</option>
<option value="canial nerves I - XII intact">CN intact</option>
<option value="sensory and motor nerves intact">SM intact</option>
<option value="cerebelar nerves intact">cere int</option>
<option value="no Babinki">no bab</option>
<option value="deep tendon reflexes bilaterally equal and reactive">DTR's =</option>
</select></td></tr>
!;
if ($sex eq 'M'){
    $PE .=     qq!<tr><td><input type=text name="Prostate Exam Text" size="20" /></td>
<td><input type=text name="Testes, Penis Exam Text" size="20" /></td>!;
}
if ($sex eq 'F'){
    $PE .=     qq!<tr><td><input type=text name="External Female Genital Exam Text" size="20" /></td>
<td><input type=text name="Speculum Exam Text" size="20" /></td>
<td><input type=text name="Internal Exam Text" size="20" /></td>!;
}
$PE .= qq!<td><input type=text name="Extremities Exam Text" size="20" /></td>
<td><input type=text name="Pulses Exam Text" size="20" /></td>
<td><input type=text name="Neurologic Exam Text" size="20" /></td></tr>
</table>!;

#####################################################################  Data Review
$DR= qq!<table>
<tr><td>Reviewed test results with patient
<select name="Review Patient" >
<option value="   "></option>
<option value="Yes">Yes</option>
<option value="No">No</option>
</select></td>
<td>Performing MD
<select name="Review physician">
<option value="   "></option>
<option value="Yes">Yes</option>
<option value="No">No</option>
</select></td>
<td>Lab tests
<select name="Review labs">
<option value="   "></option>
<option value="Yes">Yes</option>
<option value="No">No</option>
</select></td>
<td>Radiology results
<select name="Review radiology">
<option value="   "></option>
<option value="Yes">Yes</option>
<option value="No">No</option>
</select></td>
<td colspan="2">Other
<input type=text name="Review other" size=20/></td></tr></table>!;

######################################################################  
  $page .= qq!
<input type="hidden" name="Problem_List" value="@problem_id">
<table class="Container">
<tr><td><h1>$title $fname $lname</h1></td><td>DOB: $DOB</td><td>Age: $age</td><td>PID: $patient_id</td></tr>
<tr><td colspan="3"><fieldset><legend>Chief Complaint</legend>$CC</fieldset></td></tr>
<tr><td colspan="8"><fieldset><legend>History of Present Illness</legend>$HPI</fieldset></td></tr>
<tr><td colspan="8"><fieldset><legend>Review of Systems</legend>$ROS</fieldset></td></tr>
<tr><td colspan="8"><fieldset><legend>Past, Social, and Family History</legend>$FSH</fieldset></td></tr>
<tr><td colspan="10"><fieldset><legend>Physical Exam</legend>$PE</fieldset></td></tr>
<tr><td colspan="8"><fieldset><legend>Data Review</legend>$DR</fieldset></td></tr>
<tr><td colspan="8"></td></tr>
</table>
!;

return $page;
}

####################################################################################################
##

sub Insert_SO {
  my $patient_id = shift;
  my (@problem_id, $sql, $sth, $Concerns, $Location, $Quality, $Quantity, $Timing, $Setting, $Aggravating_relieving, $Associated_manifestations, $Patient_reaction, $HPI, $ROS, $PFSH, $EXAM);
  @problem_id = split(/ /,param("Problem_List"));
  $HPI = $ROS = $PFSH = $EXAM = 0;

  $sql = qq!INSERT INTO pnotes
(date, pid, user, Chief_complaint, Concerns, Location, Quality, Quantity, Timing, Setting, Aggravating_relieving, Associated_manifestations, Patient_reaction, !;
  if (param("Pain") ){$sql .= qq!Pain, !;} 
  if (param("General")){$sql .= qq!General, !;} 
  if (param("Skin")){$sql .= qq!Skin, !;} 
  if (param("Head")){$sql .= qq!Head, !;} 
  if (param("Eyes")){$sql .= qq!Eyes, !;} 
  if (param("Ears")){$sql .= qq!Ears, !;} 
  if (param("Nose and Sinuses")){$sql .= qq!Nose_sinuses, !;} 
  if (param("Mouth and Throat")){$sql .= qq!Mouth_throat, !;} 
  if (param("Neck")){$sql .= qq!Neck, !;} 
  if (param("Breasts")){$sql .= qq!Breasts, !;} 
  if (param("Respiratory")){$sql .= qq!Respiratory, !;} 
  if (param("Cardiac")){$sql .= qq!Cardiac, !;} 
  if (param("GI")){$sql .= qq!Gi, !;} 
  if (param("GU")){$sql .= qq!Gu, !;} 
  if (param("Male Genital")){$sql .= qq!Male, !;} 
  if (param("Female Genital")){$sql .= qq!Female, !;} 
  if (param("Peripheral Vascular")){$sql .= qq!Vascular, !;} 
  if (param("Neurological")){$sql .= qq!Neurological, !;} 
  if (param("Musc-Skel")){$sql .= qq!Musc, !;} 
  if (param("Endo")){$sql .= qq!Endo, !;} 
  if (param("Heme")){$sql .= qq!Heme, !;} 
  if (param("Psych")){$sql .= qq!Psych, !;} 
  if (param("Other Symptoms")){$sql .= qq!Other_symptoms, !;} 
  if (param("Nutritional Needs")){$sql .= qq!Nutritional, !;} 
  if (param("Psych Needs")){$sql .= qq!Psych_needs, !;} 
  if (param("Educational Needs")){$sql .= qq!Educational_needs, !;}
  if (param("Blood Pressure")){$sql .= qq!Blood_pressure, !;} 
  if (param("Heart Rate")){$sql .= qq!Heart_rate, !;} 
  if (param("Respiratory Rate")){$sql .= qq!Resp_rate, !;} 
  if (param("Temperature")){$sql .= qq!Temp, !;} 
  if (param("Blood Glucose")){$sql .= qq!Blood_glucose, !;} 
  if (param("Height")){$sql .= qq!Height, !;} 
  if (param("Weight")){$sql .= qq!Weight, !;} 
  if (param("General_Exam") || param("General Exam Text")){$sql .= qq!General_exam, !;} 
  if (param("Skin Exam") || param("Skin Exam Text")){$sql .= qq!Skin_exam, !;} 
  if (param("Eye Exam") || param("Eye Exam Text")){$sql .= qq!Eye_exam, !;} 
  if (param("Ear Exam") || param("Ear Exam Text")){$sql .= qq!Ear_exam, !;} 
  if (param("Nose Exam") || param("Nose Exam Text")){$sql .= qq!Nose_exam, !;} 
  if (param("Mouth Exam") || param("Mouth Exam Text")){$sql .= qq!Mouth_exam, !;} 
  if (param("Neck Exam") || param("Neck Exam Text")){$sql .= qq!Neck_exam, !;} 
  if (param("Thyroid Exam") || param("Thyroid Exam Text")){$sql .= qq!Thyroid_exam, !;} 
  if (param("Lymph Node Exam") || param("Lymph Node Exam Text")){$sql .= qq!Lymph_exam, !;} 
  if (param("Chest Exam") || param("Chest Exam Text")){$sql .= qq!Chest_exam, !;} 
  if (param("Lungs Exam") || param("Lungs Exam Text")){$sql .= qq!Lung_exam, !;} 
  if (param("Heart Exam") || param("Heart Exam Text")){$sql .= qq!Heart_exam, !;} 
  if (param("Breast Exam") || param("Breast Exam Text")){$sql .= qq!Breast_exam, !;} 
  if (param("Abdomen Exam") || param("Abdomen Exam Text")){$sql .= qq!Abdomen_exam, !;} 
  if (param("Rectal Exam") || param("Rectal Exam Text")){$sql .= qq!Rectal_exam, !;} 
  if (param("Prostate Exam") || param("Prostate Exam Text")){$sql .= qq!Prostate_exam, !;} 
  if (param("Testes, Penis Exam") || param("Testes, Penis Exam Text")){$sql .= qq!Testespenis_exam, !;} 
  if (param("External Female Exam") || param("External Female Exam Text")){$sql .= qq!External_female_exam, !;} 
  if (param("Speculum Exam") || param("Speculum Exam Text")){$sql .= qq!Speculum_exam, !;} 
  if (param("Internal Exam") || param("Internal Exam Text")){$sql .= qq!Internal_exam, !;} 
  if (param("Extremities Exam") || param("Extremities Exam Text")){$sql .= qq!Extremities_exam, !;}
  if (param("Pulses Exam") || param("Pulses Exam Text")){$sql .= qq!Pulses_exam, !;}
  if (param("Neurologic Exam") || param("Neurologic Exam Text")){$sql .= qq!Neurologic_exam, !;}
  chop $sql; chop $sql;
  $sql .= qq!) VALUES ('!.todays_date().qq!', '!.$patient_id.qq!', '!.param('hidden_provider_id').qq!', '!.param('Problem_List').qq!', ' !;
  foreach (@problem_id){
    if (param("$_ concerns")){$sql .= param("$_ concerns").qq![$_]\t!; $HPI++;}
  }
  substr($sql, -1) = qq!', ' !;
  foreach (@problem_id){
    if (param("$_ Location")){$sql .= param("$_ Location").qq![$_]\t!; $HPI++;}
  }
  substr($sql, -1) = qq!', ' !;
  foreach (@problem_id){
    if (param("$_ Quality")){$sql .= param("$_ Quality").qq![$_]\t!; $HPI++;}
  }
  substr($sql, -1) = qq!', ' !;
  foreach (@problem_id){
    if (param("$_ Quantity")){$sql .= param("$_ Quantity").qq![$_]\t!; $HPI++}
  }
  substr($sql, -1) = qq!', ' !;
  foreach (@problem_id){
    if (param("$_ Timing")){$sql .= param("$_ Timing").qq![$_]\t!; $HPI++;}
  }
  substr($sql, -1) = qq!', ' !;
  foreach (@problem_id){
    if (param("$_ Setting")){$sql .= param("$_ Setting").qq![$_]\t!; $HPI++;}
  }
  substr($sql, -1) = qq!', ' !;
  foreach (@problem_id){
    if (param("$_ Aggravating Relieving")){$sql .= param("$_ Aggravating Relieving").qq![$_]\t!; $HPI++;}
  }
  substr($sql, -1) = qq!', ' !;
  foreach (@problem_id){
    if (param("$_ Associated Manifestations")){$sql .= param("$_ Associated Manifestations").qq![$_]\t!; $HPI++;}
  }
  substr($sql, -1) = qq!', ' !;
  foreach (@problem_id){
    if (param("$_ Patient Reaction")){$sql .= param("$_ Patient Reaction").qq![$_]\t!; $HPI++;}
  }
  substr($sql, -1) = qq!', '!;
  if (param("Pain")){
    if (param("Pain") eq "NO"){
      $sql .= "No pain"; $ROS++;
    } else {
      $sql .= param("Pain Scale").qq! out of 10 pain in the !.param("Pain Location").qq!', '!; $ROS++;
    }
  }
  if (param("General")){foreach (param("General")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Skin")){foreach (param("Skin")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Head")){foreach (param("Head")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Eyes")){foreach (param("Eyes")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Ears")){foreach (param("Ears")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Nose and Sinuses")){foreach (param("Nose and Sinuses")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Mouth and Throat")){foreach (param("Mouth and Throat")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Neck")){foreach (param("Neck")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Breasts")){foreach (param("Breasts")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Respiratory")){foreach (param("Respiratory")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Cardiac")){foreach (param("Cardiac")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("GI")){foreach (param("GI")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("GU")){foreach (param("GU")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Male Genital")){foreach (param("Male Genital")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Female Genital")){foreach (param("Female Genital")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Peripheral Vascular")){foreach (param("Peripheral Vascular")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Neurological")){foreach (param("Neurological")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Musc-Skel")){foreach (param("Musc-Skel")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Endo")){foreach (param("Endo")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Heme")){foreach (param("Heme")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Psych")){foreach (param("Psych")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Other Symptoms")){foreach (param("Other Symptoms")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Nutritional Needs")){foreach (param("Nutritional Needs")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Psych Needs")){foreach (param("Psych Needs")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
  if (param("Educational Needs")){foreach (param("Educational Needs")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!; $ROS++;}
if (param("Blood Pressure") || param("Heart Rate") || param("Respiratory Rate") || param("Temperature") || param("Blood Glucose") || param("Height") || param("Weight")){$EXAM++;}
  if (param("Blood Pressure")){foreach (param("Blood Pressure")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
  if (param("Heart Rate")){foreach (param("Heart Rate")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
  if (param("Respiratory Rate")){foreach (param("Respiratory Rate")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
  if (param("Temperature")){foreach (param("Temperature")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
  if (param("Blood Glucose")){foreach (param("Blood Glucose")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
  if (param("Height")){foreach (param("Height")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
  if (param("Weight")){foreach (param("Weight")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
  if (param("General_Exam")){foreach (param("General_Exam")){$sql .=$_.qq!, !;}substr($sql, -2)= qq!', '!; $EXAM++;}
  if (param("General Exam Text")){if (param("General_Exam")){substr($sql, -4)= qq!, !.param("General Exam Text").qq!', '!;} else {$sql .= param("General Exam Text").qq!', '!; $EXAM++;}}
  if (param("Skin Exam")){foreach (param("Skin Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Skin Exam Text")){if (param("Skin Exam")){substr($sql, -4)= qq!, !.param("Skin Exam Text").qq!', '!;} else {$sql .= param("Skin Exam Text").qq!', '!; $EXAM++;}}
  if (param("Eye Exam")){foreach (param("Eye Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Eye Exam Text")){if (param("Eye Exam")){substr($sql, -4)= qq!, !.param("Eye Exam Text").qq!', '!;} else {$sql .= param("Eye Exam Text").qq!', '!; $EXAM++;}}
  if (param("Ear Exam")){foreach (param("Ear Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Ear Exam Text")){if (param("Ear Exam")){substr($sql, -4)= qq!, !.param("Ear Exam Text").qq!', '!;} else {$sql .= param("Ear Exam Text").qq!', '!; $EXAM++;}}
  if (param("Nose Exam")){foreach (param("Nose Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Nose Exam Text")){if (param("Nose Exam")){substr($sql, -4)= qq!, !.param("Nose Exam Text").qq!', '!;} else {$sql .= param("Nose Exam Text").qq!', '!; $EXAM++;}}
  if (param("Mouth Exam")){foreach (param("Mouth Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Mouth Exam Text")){if (param("Mouth Exam")){substr($sql, -4)= qq!, !.param("Mouth Exam Text").qq!', '!;} else {$sql .= param("Mouth Exam Text").qq!', '!; $EXAM++;}}
  if (param("Neck Exam")){foreach (param("Neck Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Neck Exam Text")){if (param("Neck Exam")){substr($sql, -4)= qq!, !.param("Neck Exam Text").qq!', '!;} else {$sql .= param("Neck Exam Text").qq!', '!; $EXAM++;}}
  if (param("Thyroid Exam")){foreach (param("Thyroid Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Thyroid Exam Text")){if (param("Thyroid Exam")){substr($sql, -4)= qq!, !.param("Thyroid Exam Text").qq!', '!;} else {$sql .= param("Thyroid Exam Text").qq!', '!; $EXAM++;}}
  if (param("Lymph Node Exam")){foreach (param("Lymph Node Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Lymph Node Exam Text")){if (param("Lymph Node Exam")){substr($sql, -4)= qq!, !.param("Lymph Node Exam Text").qq!', '!;} else {$sql .= param("Lymph Node Exam Text").qq!', '!; $EXAM++;}}
  if (param("Chest Exam")){foreach (param("Chest Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Chest Exam Text")){if (param("Chest Exam")){substr($sql, -4)= qq!, !.param("Chest Exam Text").qq!', '!;} else {$sql .= param("Chest Exam Text").qq!', '!; $EXAM++;}}
  if (param("Lungs Exam")){foreach (param("Lungs Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Lungs Exam Text")){if (param("Lungs Exam")){substr($sql, -4)= qq!, !.param("Lungs Exam Text").qq!', '!;} else {$sql .= param("Lungs Exam Text").qq!', '!; $EXAM++;}}
  if (param("Heart Exam")){foreach (param("Heart Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Heart Exam Text")){if (param("Heart Exam")){substr($sql, -4)= qq!, !.param("Heart Exam Text").qq!', '!;} else {$sql .= param("Heart Exam Text").qq!', '!; $EXAM++;}}
  if (param("Breast Exam")){foreach (param("Breast Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Breast Exam Text")){if (param("Breast Exam")){substr($sql, -4)= qq!, !.param("Breast Exam Text").qq!', '!;} else {$sql .= param("Breast Exam Text").qq!', '!; $EXAM++;}}
  if (param("Abdomen Exam")){foreach (param("Abdomen Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Abdomen Exam Text")){if (param("Abdomen Exam")){substr($sql, -4)= qq!, !.param("Abdomen Exam Text").qq!', '!;} else {$sql .= param("Abdomen Exam Text").qq!', '!; $EXAM++;}}
  if (param("Rectal Exam")){foreach (param("Rectal Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Rectal Exam Text")){if (param("Rectal Exam")){substr($sql, -4)= qq!, !.param("Rectal Exam Text").qq!', '!;} else {$sql .= param("Rectal Exam Text").qq!', '!; $EXAM++;}}
  if (param("Prostate Exam")){foreach (param("Prostate Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Prostate Exam Text")){if (param("Prostate Exam")){substr($sql, -4)= qq!, !.param("Prostate Exam Text").qq!', '!;} else {$sql .= param("Prostate Exam Text").qq!', '!; $EXAM++;}}
  if (param("Testes, Penis Exam")){foreach (param("Testes, Penis Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Testes, Penis Exam Text")){if (param("Testes, Penis Exam")){substr($sql, -4)= qq!, !.param("Testes, Penis Exam Text").qq!', '!;} else {$sql .= param("Testes, Penis Exam Text").qq!', '!; $EXAM++;}}
  if (param("External Female Genital Exam")){foreach (param("External Female Genital Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("External Female Exam Text")){if (param("External Female Genital Exam")){substr($sql, -4)= qq!, !.param("External Female Genital Exam Text").qq!', '!;} else {$sql .= param("External Female Genital Exam Text").qq!', '!; $EXAM++;}}
  if (param("Speculum Exam")){foreach (param("Speculum Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Speculum Exam Text")){if (param("Speculum Exam")){substr($sql, -4)= qq!, !.param("Speculum Exam Text").qq!', '!;} else {$sql .= param("Speculum Exam Text").qq!', '!; $EXAM++;}}
  if (param("Internal Exam")){foreach (param("Internal Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Internal Exam Text")){if (param("Internal Exam")){substr($sql, -4)= qq!, !.param("Internal Exam Text").qq!', '!;} else {$sql .= param("Internal Exam Text").qq!', '!; $EXAM++;}}
  if (param("Extremities Exam")){foreach (param("Extremities Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Extremities Exam Text")){if (param("Extremities Exam")){substr($sql, -4)= qq!, !.param("Extremities Exam Text").qq!', '!;} else {$sql .= param("Extremities Exam Text").qq!', '!; $EXAM++;}}
  if (param("Pulses Exam")){foreach (param("Pulses Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Pulses Exam Text")){if (param("Pulses Exam")){substr($sql, -4)= qq!, !.param("Pulses Exam Text").qq!', '!;} else {$sql .= param("Pulses Exam Text").qq!', '!; $EXAM++;}}
  if (param("Neurologic Exam")){foreach (param("Neurologic Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!; $EXAM++;}
  if (param("Neurologic Exam Text")){if (param("Neurologic Exam")){substr($sql, -4)= qq!, !.param("Neurologic Exam Text").qq!', '!;} else {$sql .= param("Neurologic Exam Text").qq!', '!; $EXAM++;}}
  substr($sql, -3)=qq!!;
  $sql .= qq!)!;
  $sth = $dbh->prepare($sql);
  $sth->execute;
  ######################################### Insert Past/Social/Family History
  if (param("coffee") || param("alcohol") || param("drug") || param("sleep_patterns") || param("exercise_patterns") || param("std") || param("reproduction") || param("sexual_function") || param("self_breast_exam") || param("self_testicle_exam") || param("seatbelt_use") || param("counseling") || param("hazardous_activities") || param("history_mother") || param("history_father") || param("history_siblings") || param("history_offspring") || param("history_spouse") || param("relatives_cancer") || param("relatives_tuberculosis") || param("relatives_diabetes") || param("relatives_hypertension") || param("relatives_heart_problems") || param("relatives_stroke") || param("relatives_epilepsy") || param("relatives_mental_illness") || param("relatives_suicide")){
    $sql = qq!INSERT INTO history_data (pid, !;
    if (param("coffee")){$sql .= qq!coffee, !; $PFSH++;}
    if (param("alcohol")){$sql .= qq!alcohol, !; $PFSH++;}
    if (param("drug")){$sql .= qq!drug_use, !; $PFSH++;}
    if (param("sleep_patterns")){$sql .= qq!sleep_patterns, !; $PFSH++;}
    if (param("exercise_patterns")){$sql .= qq!exercise_patterns, !; $PFSH++;}
    if (param("std")){$sql .= qq!std, !; $PFSH++;}
    if (param("reproduction")){$sql .= qq!reproduction, !; $PFSH++;}
    if (param("sexual_function")){$sql .= qq!sexual_function, !; $PFSH++;}
    if (param("self_breast_exam")){$sql .= qq!self_breast_exam, !; $PFSH++;}
    if (param("self_testicle_exam")){$sql .= qq!self_testicle_exam, !; $PFSH++;}
    if (param("seatbelt_use")){$sql .= qq!seatbelt_use, !; $PFSH++;}
    if (param("counseling")){$sql .= qq!counseling, !; $PFSH++;}
    if (param("hazardous_activities")){$sql .= qq!hazardous_activities, !; $PFSH++;}
    if (param("history_mother")){$sql .= qq!history_mother, !; $PFSH++;}
    if (param("history_father")){$sql .= qq!history_father, !; $PFSH++;}
    if (param("history_siblings")){$sql .= qq!history_siblings, !; $PFSH++;}
    if (param("history_offspring")){$sql .= qq!history_offspring, !; $PFSH++;}
    if (param("history_spouse")){$sql .= qq!history_spouse, !; $PFSH++;}
    if (param("relatives_cancer")){$sql .= qq!relatives_cancer, !; $PFSH++;}
    if (param("relatives_tuberculosis")){$sql .= qq!relatives_tuberculosis, !; $PFSH++;}
    if (param("relatives_diabetes")){$sql .= qq!relatives_diabetes, !; $PFSH++;}
    if (param("relatives_hypertension")){$sql .= qq!relatives_hypertension, !; $PFSH++;}
    if (param("relatives_heart_problems")){$sql .= qq!relatives_heart_problems, !; $PFSH++;}
    if (param("relatives_stroke")){$sql .= qq!relatives_stroke, !; $PFSH++;}
    if (param("relatives_epilepsy")){$sql .= qq!relatives_epilepsy, !; $PFSH++;}
    if (param("relatives_mental_illness")){$sql .= qq!relatives_mental_illness, !; $PFSH++;}
    if (param("relatives_suicide")){$sql .= qq!relatives_suicide, !; $PFSH++;}
    substr($sql, -2) = qq!) VALUES ('!.$patient_id.qq!', '!;
		       if (param("coffee")){$sql .= param("coffee").qq!', '!;}
		       if (param("alcohol")){$sql .= param("alcohol").qq!', '!;}
		       if (param("drug")){$sql .= param("drug").qq!', '!;}
		       if (param("sleep_patterns")){$sql .= param("sleep_patterns").qq!', '!;}
		       if (param("exercise_patterns")){$sql .= param("exercise_patterns").qq!', '!;}
		       if (param("std")){$sql .= param("std").qq!', '!;}
		       if (param("reproduction")){$sql .= param("reproduction").qq!', '!;}
		       if (param("sexual_function")){$sql .= param("sexual_function").qq!', '!;}
		       if (param("self_breast_exam")){$sql .= param("self_breast_exam").qq!', '!;}
		       if (param("self_testicle_exam")){$sql .= param("self_testicle_exam").qq!', '!;}
		       if (param("seatbelt_use")){$sql .= param("seatbelt_use").qq!', '!;}
		       if (param("counseling")){$sql .= param("counseling").qq!', '!;}
		       if (param("hazardous_activities")){$sql .= param("hazardous_activities").qq!', '!;}
		       if (param("history_mother")){$sql .= param("history_mother").qq!', '!;}
		       if (param("history_father")){$sql .= param("history_father").qq!', '!;}
		       if (param("history_siblings")){$sql .= param("history_siblings").qq!', '!;}
		       if (param("history_offspring")){$sql .= param("history_offspring").qq!', '!;}
		       if (param("history_spouse")){$sql .= param("history_spouse").qq!', '!;}
		       if (param("relatives_cancer")){$sql .= param("relatives_cancer").qq!', '!;}
		       if (param("relatives_tuberculosis")){$sql .= param("relatives_tuberculosis").qq!', '!;}
		       if (param("relatives_diabetes")){$sql .= param("relatives_diabetes").qq!', '!;}
		       if (param("relatives_hypertension")){$sql .= param("relatives_hypertension").qq!', '!;}
		       if (param("relatives_heart_problems")){$sql .= param("relatives_heart_problems").qq!', '!;}
		       if (param("relatives_stroke")){$sql .= param("relatives_stroke").qq!', '!;}
		       if (param("relatives_epilepsy")){$sql .= param("relatives_epilepsy").qq!', '!;}
		       if (param("relatives_mental_illness")){$sql .= param("relatives_mental_illness").qq!', '!;}
		       if (param("relatives_suicide")){$sql .= param("relatives_suicide").qq!', '!;}
		       substr($sql, -4) = qq!')!;
    $sth = $dbh->prepare($sql);
    $sth->execute;
  }
if ($ROS ==0){}
}

####################################################################################
##  Screening and Prevention
##  Given:  Sex, DOB by passing, patient_id by paramameter
##  Returns: Table

sub Screening_Prevention {
  my ($patient_id, $sex, $DOB) = @_;
  my ($sql, $sth, $prevention);
  my ($title, $lname, $fname, $last_prostate_exam, $prostate_note, $last_psa, $psa_note, $last_gynocological_exam, $gyn_note, $last_breast_exam, $breast_exam_note, $last_mammogram, $mammogram_note, $last_sigmoidoscopy_colonoscopy, $colonoscopy_note, $last_fecal_occult_blood, $fecal_occult_blood_note, $last_ppd, $PPD_note, $last_bone_density, $bone_density_note, $date_ordered, $date_completed, $note, $c, @param_names, @tests, @PSA_names, @GYN_names, @MAMMO_names, @COLONOSCOPY_names, @FOB_names, @DEXA_names, @PPD_names);
  $DOB =~ s/(\d+)\/(\d+)\/(\d+)/$3-$2-$1/;

  ############################### Insert Screening Prevention tests into tests
  @param_names = $cgi->param;
  @PSA_names = grep(/psa date completed .*/, @param_names);
  @GYN_names= grep(/gyn date completed .*/, @param_names);
  @MAMMO_names=grep(/mammogram date completed .*/, @param_names);
  @FOB_names=grep(/fob date completed .*/, @param_names);
  @COLONOSCOPY_names=grep(/colonoscopy date completed .*/, @param_names);
  @DEXA_names=grep(/dexa date completed .*/, @param_names);
  @PPD_names=grep(/ppd date completed .*/, @param_names);

  ######################### Prostate Exam ##################
  if (param('new prostate exam date ordered')){
    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, date_completed, provider_id, problem_id, note) VALUES ('!.$patient_id.qq!', '32465-7', '!.param('new prostate exam date ordered').qq!', '!.param('new prostate exam date ordered').qq!', '!.param('hidden_provider_id').qq!', '19315', '!.param('new prostate exam note').qq!')!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }

  ######################### PSA #############################
  if (param('new psa date ordered')){
    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, !;
    if (param('new psa date completed')){$sql .= qq!date_completed,!;}
    $sql .= qq!provider_id, problem_id!;
    if (param('new psa note')){$sql .= qq!, note!;}
    $sql .= qq!) VALUES ('!.$patient_id.qq!', '35741-8', '!.param('new psa date ordered').qq!', !;
    if (param('new psa date completed')){
      $sql .= "'".param('new psa date completed')."', ";
    }
    $sql .= qq!'!.param('hidden_provider_id').qq!', '19315'!;
    if (param('new psa note')){
      $sql .= ", '".param('new psa note')."'";
    }
    $sql .= qq!)!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }
  for (@PSA_names){
    if ($_=~/psa date completed (.*)/){$date_ordered=$1;}
    $sql = qq!UPDATE tests SET date_completed='!.param("psa date completed $date_ordered").qq!', note='!.param("psa note $date_ordered").qq!' WHERE patient_id='!.$patient_id.qq!' AND date_ordered="$date_ordered" AND loinc_num='35741-8'!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }

  ######################### Gyn #########################
  if (param('new gyn date ordered')){
    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, !;
    if (param('new gyn date completed')){$sql .= qq!date_completed, !;}
    $sql .= qq!provider_id, problem_id!;
    if (param('new gyn note')){$sql .= qq!, note!;}
    $sql .= qq!) VALUES ('!.$patient_id.qq!', '19771-5', '!.param('new gyn date ordered').qq!', !;
    if (param('new gyn date completed')){
      $sql .= "'".param('new gyn date completed')."', ";
    }
    $sql .= qq!'!.param('hidden_provider_id').qq!', '15350'!;
    if (param('new gyn note')){
      $sql .= ", '".param('new gyn note')."'";
    }
    $sql .= qq!)!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }
  for (@GYN_names){
    if ($_=~/gyn date completed (.*)/){$date_ordered=$1;}
    $sql = qq!UPDATE tests SET date_completed='!.param("gyn date completed $date_ordered").qq!', note='!.param("gyn note $date_ordered").qq!' WHERE patient_id='!.$patient_id.qq!' AND date_ordered="$date_ordered" AND loinc_num='19771-5'!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }

  ######################### Breast Exam ######################
  if (param('new breast exam date ordered')){
    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, date_completed, provider_id, problem_id, note) VALUES ('!.$patient_id.qq!', '8696-7', '!.param('new breast exam date ordered').qq!', '!.param('new breast exam date ordered').qq!', '!.param('hidden_provider_id').qq!', '18913', '!.param('new breast exam note').qq!')!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }

  ######################### Mammogram ########################
  if (param('new mammogram date ordered')){
    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, !;
    if (param('new mammogram date completed')){$sql .= qq!date_completed, !;}
    $sql .= qq!provider_id, problem_id!;
    if (param('new mammogram note')){$sql .= qq!, note!;}
    $sql .= qq!) VALUES ('!.$patient_id.qq!', '24606-6', '!.param('new mammogram date ordered').qq!', !;
    if (param('new mammogram date completed')){
      $sql .= "'".param('new mammogram date completed')."', ";
    }
    $sql .= qq!'!.param('hidden_provider_id').qq!', '18912'!;
    if (param('new mammogram note')){
      $sql .= ", '".param('new mammogram note')."'";
    }
    $sql .= qq!)!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }
  for (@MAMMO_names){
    if ($_=~/mammogram date completed (.*)/){$date_ordered=$1;}
    $sql = qq!UPDATE tests SET date_completed='!.param("mammogram date completed $date_ordered").qq!', note='!.param("mammogram note $date_ordered").qq!' WHERE patient_id='!.$patient_id.qq!' AND date_ordered="$date_ordered" AND loinc_num='24606-6'!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }

  ######################### Fecal Occult Blood #############
  if (param('new fecal occult blood date ordered')){
    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, !;
    if (param('new fecal occult blood date completed')){$sql .= qq!date_completed, !;}
    $sql .= qq!provider_id, problem_id!;
    if (param('new fecal occult blood note')){$sql .= qq!, note!;}
    $sql .= qq!) VALUES ('!.$patient_id.qq!', '2334-8', '!.param('new fecal occult blood date ordered').qq!', !;
    if (param('new fecal occult blood date completed')){
      $sql .= "'".param('new fecal occult blood date completed')."', ";
    }
    $sql .= qq!'!.param('hidden_provider_id').qq!', '19759'!;
    if (param('new fecal occult blood note')){
      $sql .= ", '".param('new fecal occult blood note')."'";
    }
    $sql .= qq!')!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }
  for (@FOB_names){
    if ($_=~/fob date completed (.*)/){$date_ordered=$1;}
    $sql = qq!UPDATE tests SET date_completed='!.param("fob date completed $date_ordered").qq!', note='!.param("fob note $date_ordered").qq!' WHERE patient_id='!.$patient_id.qq!' AND date_ordered="$date_ordered" AND loinc_num='2334-8'!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }

  ######################### Sigmoid/Colonoscopy #############
  if (param('new colonoscopy date ordered')){
    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, !;
    if (param('new colonoscopy date completed')){$sql .= qq!date_completed, !;}
    $sql .= qq!provider_id, problem_id!;
    if (param('new colonoscopy note')){$sql .= qq!, note!;}
    $sql .= qq!) VALUES ('!.$patient_id.qq!', '28022-2', '!.param('new colonoscopy date ordered').qq!', !;
    if (param('new colonoscopy date completed')){
      $sql .= "'".param('new colonoscopy date completed')."', ";
    }
    $sql .= qq!'!.param('hidden_provider_id').qq!', '19759'!;
    if (param('new colonoscopy note')){
      $sql .= ", '".param('new colonoscopy note')."'";
    }
    $sql .= qq!)!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }
  for (@COLONOSCOPY_names){
    if ($_=~/colonoscopy date completed (.*)/){$date_ordered=$1;}
    $sql = qq!UPDATE tests SET date_completed='!.param("colonoscopy date completed $date_ordered").qq!', note='!.param("colonoscopy note $date_ordered").qq!' WHERE patient_id='!.$patient_id.qq!' AND date_ordered="$date_ordered" AND loinc_num='28022-2'!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }

  ######################### DEXA ############################
  if (param('new dexa date ordered')){
    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, !;
    if (param('new dexa date completed')){$sql .= qq!date_completed, !;}
    $sql .= qq!provider_id, problem_id!;
    if (param('new dexa note')){$sql .= qq!, note!;}
    $sql .= qq!) VALUES ('!.$patient_id.qq!', '38268-9', '!.param('new dexa date ordered').qq!', !;
    if (param('new dexa date completed')){
      $sql .= "'".param('new dexa date completed')."', ";
    }
    $sql .= qq!'!.param('hidden_provider_id').qq!', '19179'!;
    if (param('new dexa note')){
      $sql .= ", '".param('new dexa note')."'";
    }
    $sql .= qq!)!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }
  for (@DEXA_names){
    if ($_=~/dexa date completed (.*)/){$date_ordered=$1;}
    $sql = qq!UPDATE tests SET date_completed='!.param("dexa date completed $date_ordered").qq!', note='!.param("dexa note $date_ordered").qq!' WHERE patient_id='!.$patient_id.qq!' AND date_ordered="$date_ordered" AND loinc_num='38268-9'!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }

  ######################### PPD #############################
  if (param('new ppd date ordered')){
    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, !;
    if (param('new ppd date completed')){$sql .= qq!date_completed, !;}
    $sql .= qq!provider_id, problem_id!;
    if (param('new ppd note')){$sql .= qq!, note!;}
    $sql .= qq!) VALUES ('!.$patient_id.qq!', '39208-4', '!.param('new ppd date ordered').qq!', !;
    if (param('new ppd date completed')){
      $sql .= "'".param('new ppd date completed')."', ";
    }
    $sql .= qq!'!.param('hidden_provider_id').qq!', '2255'!;
    if (param('new ppd note')){
      $sql .= ", '".param('new ppd note')."'";
    }
    $sql .= qq!)!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }
  for (@PPD_names){
    if ($_=~/ppd date completed (.*)/){$date_ordered=$1;}
    $sql = qq!UPDATE tests SET date_completed='!.param("ppd date completed $date_ordered").qq!', note='!.param("ppd note $date_ordered").qq!' WHERE patient_id='!.$patient_id.qq!' AND date_ordered="$date_ordered" AND loinc_num='39208-4'!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }

  ###########################################################################################################################
  ######################################## Print Screening Tests  ###########################################################
  ###########################################################################################################################

  unless ($page_name eq 'New Encounter'){
    if ($page_name eq 'Patient File'){
      $prevention =  "<table><tr><td></td><th>Date Completed</th><th>Results</th></tr>";
    } else {
      $prevention =  "<table><tr><td></td><th>Date Ordered</th><th>Date Completed</th><th>Results</th></tr>";
    }
  }

  ###########################################################################################################################
  ############################# Recommended for  Men ########################################################################
  ###########################################################################################################################

  if ($sex =~ /^M/){
    if (todays_date()-$DOB gt 14600){
      ######################### Prostate Exam ##################
      $sql = qq!SELECT date_ordered, date_completed, note FROM tests WHERE patient_id='!.$patient_id.qq!' and loinc_num='32465-7' ORDER BY date_ordered!;
      $sth = $dbh->prepare($sql);
      $sth ->execute;
      $sth ->bind_columns(\$date_ordered, \$date_completed, \$note);
      $prevention .= qq!<tr><th>Prostate Exam</th>!;
      $c=0;
      while ($sth->fetch){
	if ($c!=0){$prevention .= qq!<tr><td></td>!;}
	$prevention .= qq!<td>$date_ordered</td><td>$note</td></tr>!;
      } continue {$c++;}
      if ($page_name eq 'Update Record'){
	if ($c!=0){$prevention .= qq!<tr><td></td>!;}
	$prevention .= qq!<td><input type='text' name='new prostate exam date ordered'></td><td></td><td><input type='text' name='new prostate exam note' /></td></tr>!;
      }

      ######################### PSA ############################
      @tests=();
      $sql = qq!SELECT date_ordered, date_completed, note FROM tests WHERE patient_id='!.$patient_id.qq!' and loinc_num='35741-8' ORDER BY date_ordered!;
      $sth = $dbh->prepare($sql);
      $sth ->execute;
      $sth ->bind_columns(\$date_ordered, \$date_completed, \$note);
      while ($sth->fetch){push (@tests, [$date_ordered, $date_completed, $note]);}
      $prevention .= qq!<tr><th>PSA</th>!;
      for ($c=0;$c<=$#tests; $c++){
	if ($page_name eq 'Patient File'){
	  if ($c!=0){
	    $prevention .= qq!<tr><td></td><td>$tests[$c][0]</td>!;
	  } else {$prevention .= qq!<td>$tests[$c][0]</td>!;}
	} else {
	  if ($c!=0){$prevention .= qq!<tr><td></td><td>$tests[$c][0]</td>!;} else {
	  $prevention .= qq!<td>$tests[$c][0]</td>!;}
	}
	if ($tests[$c][2]){
	  $prevention .= qq!<td>$tests[$c][2]</td>!;
	} elsif ($page_name eq 'Update Record'){
	  $prevention .=qq!<td><input type='text' name="psa date completed $tests[$c][0]" /></td><td><input type='text' name="psa note $tests[$c][0]" /></td>!;
	} else {
	  $prevention .= qq!<td>Pending</td>!;
	}
	$prevention .= qq!</tr>!;
      }
      if ($page_name eq 'Update Record'){
	if ($#tests!=-1){$prevention .= qq!<tr><td></td>!;}
	$prevention  .= qq!<td><input type='text' name='new psa date ordered' /></td><td><input type='text' name='new psa date completed' /></td><td><input type='text' name='new psa note' /></td></tr>!;
      }
    }
  }

  ###########################################################################################################################
  #################### Recommended for Women ################################################################################
  ###########################################################################################################################

  elsif ($sex =~/^F/){

    ######################### Gyn #########################
    @tests=();
    $sql = qq!SELECT date_ordered, date_completed, note FROM tests WHERE patient_id='!.$patient_id.qq!' and loinc_num='19771-5' ORDER BY date_ordered!;
    $sth = $dbh->prepare($sql);
    $sth ->execute;
    $sth ->bind_columns(\$date_ordered, \$date_completed, \$note);
    while ($sth->fetch){push (@tests, [$date_ordered, $date_completed, $note]);}
    $prevention .= qq!<tr><th>GYN</th>!;
    for ($c=0;$c<=$#tests; $c++){
	if ($page_name eq 'Patient File'){
	  if ($c!=0){
	    $prevention .= qq!<tr><td>$tests[$c][0]</td>!;
	  } else {$prevention .= qq!<td>$tests[$c][0]</td>!;}
	} else {
	  if ($c!=0){
	    $prevention .= qq!<tr><td></td><td>$tests[$c][0]</td>!;
	  } else {
	    $prevention .= qq!<td>$tests[$c][0]</td>!;
	  }
	}
      if ($tests[$c][2]){
	$prevention .= qq!<td>$tests[$c][2]</td>!;
      } elsif ($page_name eq 'Update Record'){
	$prevention .=qq!<td><input type='text' name="gyn date completed $tests[$c][0]" /></td><td><input type='text' name="gyn note $tests[$c][0]" /></td>!;
      } else {
	$prevention .= qq!<td>Pending</td>!;
      }
      $prevention .= qq!</tr>!;
    }
    if ($page_name eq 'Update Record'){
      if ($#tests!=-1){$prevention .= qq!<tr><td></td>!;}
      $prevention  .= qq!<td><input type='text' name='new gyn date ordered' /></td><td><input type='text' name='new gyn date completed' /></td><td><input type='text' name='new gyn note' /></td></tr>!;
    }
     
    if (todays_date()-$DOB>40){
      
      ######################### Breast Exam ######################
      @tests=();
      $sql = qq!SELECT date_ordered, date_completed, note FROM tests WHERE patient_id='!.$patient_id.qq!' and loinc_num='8696-7' ORDER BY date_ordered!;
      $sth = $dbh->prepare($sql);
      $sth ->execute;
      $sth ->bind_columns(\$date_ordered, \$date_completed, \$note);
      $prevention .= qq!<tr><th>Breast Exam</th>!;
      $c=0;
      while ($sth->fetch){
	if ($c!=0){
	  if ($page_name eq 'Patient File'){
	    $prevention .= qq!<tr>!;
	  } else {
	    $prevention .= qq!<tr><td></td>!;
	  }
	}
	$prevention .= qq!<td>$date_ordered</td><td>$note</td></tr>!;
      } continue {$c++;}
      if ($page_name eq 'Update Record'){
	if ($c!=0){$prevention .= qq!<tr><td></td>!;}
	$prevention .= qq!<td><input type='text' name='new breast exam date ordered' /></td><td></td><td><input type='text' name='new breast exam note' /></td></tr>!;
      }
      
      ######################### Mammogram ########################
      @tests=();
      $sql = qq!SELECT date_ordered, date_completed, note FROM tests WHERE patient_id='!.$patient_id.qq!' and loinc_num='24606-6' ORDER BY date_ordered!;
      $sth = $dbh->prepare($sql);
      $sth ->execute;
      $sth ->bind_columns(\$date_ordered, \$date_completed, \$note);
      while ($sth->fetch){push (@tests, [$date_ordered, $date_completed, $note]);}
      $prevention .= qq!<tr><th>MAMMOGRAM</th>!;
      for ($c=0;$c<=$#tests; $c++){
	if ($page_name eq 'Patient File'){
	  if ($c!=0){
	    $prevention .= qq!<tr><td></td><td>$tests[$c][0]</td>!;
	  } else {$prevention .= qq!<td>$tests[$c][0]</td>!;}
	} else {
	  if ($c!=0){$prevention .= qq!<tr><td></td><td>$tests[$c][0]</td>!;} else {
	  $prevention .= qq!<td>$tests[$c][0]</td>!;}
	}
	if ($tests[$c][2]){
	  $prevention .= qq!<td>$tests[$c][2]</td>!;
	} elsif ($page_name eq 'Update Record'){
	  $prevention .=qq!<td><input type='text' name="mammogram date completed $tests[$c][0]" /></td><td><input type='text' name="mammogram note $tests[$c][0]" /></td>!;
	} else {
	  $prevention .= qq!<td>Pending</td>!;
	}
	$prevention .= qq!</tr>!;
      }
      if ($page_name eq 'Update Record'){
	if  ($#tests!=-1){$prevention .= qq!<tr><td></td>!;}
	$prevention  .= qq!<td><input type='text' name='new mammogram date ordered' /></td><td><input type='text' name='new mammogram date completed' /></td><td><input type='text' name='new mammogram note' /></td></tr>!;
      }
    }
  }
  
  ###########################################################################################################################
  #################### Recommended for Men and Women ########################################################################
  ###########################################################################################################################
  
  if (todays_date()-$DOB>=50){
    
    ######################### Fecal Occult Blood #############
    if (todays_date()-$last_sigmoidoscopy_colonoscopy >=10){
      @tests=();
      $sql = "SELECT date_ordered, date_completed, note FROM tests WHERE patient_id='".$patient_id."' and loinc_num='2334-8' ORDER BY date_ordered";
      $sth = $dbh->prepare($sql);
      $sth ->execute;
      $sth ->bind_columns(\$date_ordered, \$date_completed, \$note);
      while ($sth->fetch){push (@tests, [$date_ordered, $date_completed, $note]);}
      $prevention .= qq!<tr><th>FOB</th>!;
      for ($c=0;$c<=$#tests; $c++){
	if ($page_name eq 'Patient File'){
	  if ($c!=0){
	    $prevention .= qq!<tr><td></td><td>$tests[$c][0]</td>!;
	  } else {$prevention .= qq!<td>$tests[$c][0]</td>!;}
	} else {
	  if ($c!=0){$prevention .= qq!<tr><td></td><td>$tests[$c][0]</td>!;} else {
	  $prevention .= qq!<td>$tests[$c][0]</td>!;}
	}
	if ($tests[$c][2]){
	  $prevention .= qq!<td>$tests[$c][2]</td>!;
	} elsif ($page_name eq 'Update Record'){
	  $prevention .=qq!<td><input type='text' name="fob date completed $tests[$c][0]" /></td><td><input type='text' name="fob note $tests[$c][0]" /></td>!;
	} else {
	  $prevention .= qq!<td>Pending</td>!;
	}
	$prevention .= qq!</tr>!;
      }
      if ($page_name eq 'Update Record'){
	if ($#tests!=-1){$prevention .= qq!<tr><td></td>!;}
	$prevention  .= qq!<input type='text' name='new fob date ordered' /></td><td><input type='text' name='new fob date completed' /></td><td><input type='text' name='new fob note' /></td></tr>!;
      }
      
      ######################### Sigmoid/Colonoscopy #############
      @tests=();
      $sql = qq!SELECT date_ordered, date_completed, note FROM tests WHERE patient_id='!.$patient_id.qq!' and loinc_num='28022-2' ORDER BY date_ordered!;
      $sth = $dbh->prepare($sql);
      $sth ->execute;
      $sth ->bind_columns(\$date_ordered, \$date_completed, \$note);
      while ($sth->fetch){push (@tests, [$date_ordered, $date_completed, $note]);}
      $prevention .= qq!<tr><th>COLONOSCOPY</th>!;
      for ($c=0;$c<=$#tests; $c++){
	if ($page_name eq 'Patient File'){
	  if ($c!=0){
	    $prevention .= qq!<tr><td></td><td>$tests[$c][0]</td>!;
	  } else {$prevention .= qq!<td>$tests[$c][0]</td>!;}
	} else {
	  if ($c!=0){$prevention .= qq!<tr><td></td><td>$tests[$c][0]</td>!;} else {
	  $prevention .= qq!<td>$tests[$c][0]</td>!;}
	}
	if ($tests[$c][2]){
	  $prevention .= qq!<td>$tests[$c][2]</td>!;
	} elsif ($page_name eq 'Update Record'){
	  $prevention .=qq!<td><input type='text' name="colonoscopy date completed $tests[$c][0]" /></td><td><input type='text' name="colonoscopy note $tests[$c][0]" /></td>!;
	} else {
	  $prevention .= qq!<td>Pending</td>!;
	}
	$prevention .= qq!</tr>!;
      }
      if ($page_name eq 'Update Record'){
	if ($#tests!=-1){$prevention .= qq!<tr><td></td>!;}
	$prevention  .= qq!<td><input type='text' name='new colonoscopy date ordered' /></td><td><input type='text' name='new colonoscopy date completed' /></td><td><input type='text' name='new colonoscopy note' /></td></tr>!;
      }
    }
  }
  
  if (todays_date()-$DOB>=65){
    
    ######################### DEXA ############################
    @tests=();
    $sql = qq!SELECT date_ordered, date_completed, note FROM tests WHERE patient_id='!.$patient_id.qq!' and loinc_num='38268-9' ORDER BY date_ordered!;
    $sth = $dbh->prepare($sql);
    $sth ->execute;
    $sth ->bind_columns(\$date_ordered, \$date_completed, \$note);
    while ($sth->fetch){push (@tests, [$date_ordered, $date_completed, $note]);}
    $prevention .= qq!<tr><th>DEXA</th>!;
    for ($c=0;$c<=$#tests; $c++){
	if ($page_name eq 'Patient File'){
	  if ($c!=0){
	    $prevention .= qq!<tr><td></td><td>$tests[$c][0]</td>!;
	  } else {$prevention .= qq!<td>$tests[$c][0]</td>!;}
	} else {
	  if ($c!=0){$prevention .= qq!<tr><td></td><td>$tests[$c][0]</td>!;} else {
	  $prevention .= qq!<td>$tests[$c][0]</td>!;}
	}
      if ($tests[$c][2]){
	$prevention .= qq!<td>$tests[$c][2]</td>!;
      } elsif ($page_name eq 'Update Record'){
	$prevention .=qq!<td><input type='text' name="dexa date completed $tests[$c][0]" /></td><td><input type='text' name="dexa note $tests[$c][0]" /></td>!;
      } else {
	$prevention .= qq!<td>Pending</td>!;
      }
      $prevention .= qq!</tr>!;
    }
    if ($page_name eq 'Update Record'){
      if  ($#tests!=-1){$prevention .= qq!<tr><td></td>!;}
      $prevention  .= qq!<td><input type='text' name='new dexa date ordered' /></td><td><input type='text' name='new dexa date completed' /></td><td><input type='text' name='new dexa note' /></td></tr>!;
    }
  }

  ########################### PPD ###########################################
  @tests=();
  $sql = qq!SELECT date_ordered, date_completed, note FROM tests WHERE patient_id='!.$patient_id.qq!' and loinc_num='39208-4' ORDER BY date_ordered!;
  $sth = $dbh->prepare($sql);
  $sth ->execute;
  $sth ->bind_columns(\$date_ordered, \$date_completed, \$note);
  while ($sth->fetch){push (@tests, [$date_ordered, $date_completed, $note]);}
  $prevention .= qq!<tr><th>PPD</th>!;
  for ($c=0;$c<=$#tests; $c++){
    if ($page_name eq 'Patient File'){
      if ($c!=0){
	$prevention .= qq!<tr><td></td><td>$tests[$c][0]</td>!;
      } else {$prevention .= qq!<td>$tests[$c][0]</td>!;}
    } else {
	  if ($c!=0){$prevention .= qq!<tr><td></td><td>$tests[$c][0]</td>!;} else {
	  $prevention .= qq!<td>$tests[$c][0]</td>!;}
    }
    if ($tests[$c][2]){
      $prevention .= qq!<td>$tests[$c][2]</td>!;
    } elsif ($page_name eq 'Update Record'){
      $prevention .=qq!<td><input type='text' name="ppd date completed $tests[$c][0]" /></td><td><input type='text' name="ppd note $tests[$c][0]" /></td>!;
    } else {
      $prevention .= qq!<td>Pending</td>!;
    }
    $prevention .= qq!</tr>!;
  }
  if ($page_name eq 'Update Record'){
    if ($#tests!=-1){$prevention .= qq!<tr><td></td>!;}
    $prevention  .= qq!<td><input type='text' name='new ppd date ordered' /></td><td><input type='text' name='new ppd date completed' /></td><td><input type='text' name='new ppd note' /></td></tr>!;
  }
  if ($prevention eq qq!<table><tr><th>Screening</th></tr>!){
    $prevention .=qq!<tr><td>No screening test have been done.</td></tr>!;
  }
  $prevention .= qq!</table>!;
  return $prevention;
}

#############################################################################################
##  Immunizations
##  Passed:  DOB
##  Returns: table

sub Immunizations {
  my ($patient_id, $DOB) = @_;
  $DOB =~ s/(\d+)\/(\d+)\/(\d+)/$3-$1-$2/;
  my ($sql, $sth, $ref, $immunizations);
  my %immunization_hash;

  ############################################################  Insert into database

  if (param('Td')){
    $sql = qq!INSERT into immunizations 
(patient_id, administered_date, immunization_id) 
VALUES ('!.$patient_id.qq!','!.param('Td').qq!','32')!;
    $sth = $dbh ->prepare($sql);
    $sth->execute;
  }
  if (param('Influenza 1')){
    $sql = qq!INSERT INTO immunizations 
(patient_id, administered_date, immunization_id) 
VALUES ('!.$patient_id.qq!','!.param('Influenza 1').qq!','30')!;
    $sth = $dbh ->prepare($sql);
    $sth->execute;
  }
  if (param('Pneumococcal Conjugate 1')){
    $sql = qq!INSERT INTO immunizations 
(patient_id, administered_date, immunization_id) 
VALUES ('!.$patient_id.qq!','!.param('Pneumococcal Conjugate 1').qq!','19')!;
    $sth = $dbh ->prepare($sql);
    $sth->execute;
  }
  if (param('Hepatitis B 1')){
    $sql = qq!INSERT INTO immunizations 
(patient_id, administered_date, immunization_id) 
VALUES ('!.$patient_id.qq!','!.param('Hepatitis B 1').qq!','27')!;
    $sth = $dbh ->prepare($sql);
    $sth->execute;
  }
  if (param('Hepatitis B 2')){
    $sql = qq!INSERT INTO immunizations 
(patient_id, administered_date, immunization_id) 
 VALUES ('!.$patient_id.qq!','!.param('Hepatitis B 2').qq!','28')!;
    $sth = $dbh ->prepare($sql);
    $sth->execute;
  }
  if (param('Hepatitis B 3')){
    $sql = qq!INSERT INTO immunizations 
(patient_id, administered_date, immunization_id)  
VALUES ('!.$patient_id.qq!','!.param('Hepatitis B 3').qq!','29')!;
    $sth = $dbh ->prepare($sql);
    $sth->execute;
  }
  if (param('Hepatitis A 1')){
    $sql = qq!INSERT INTO immunizations 
(patient_id, administered_date, immunization_id) 
VALUES ('!.$patient_id.qq!','!.param('Hepatitis A 1').qq!','33')!;
    $sth = $dbh ->prepare($sql);
    $sth->execute;
  }
  if (param('Hepatitis A 2')){
    $sql = qq!INSERT INTO immunizations 
(patient_id, administered_date, immunization_id) 
 VALUES ('!.$patient_id.qq!','!.param('Hepatitis A 2').qq!','34')!;
    $sth = $dbh ->prepare($sql);
    $sth->execute;
  }
  if (param('MMR 1')){
    $sql = qq!INSERT INTO immunizations 
(patient_id, administered_date, immunization_id) 
VALUES ('!.$patient_id.qq!','!.param('MMR 1').qq!','23')!;
    $sth = $dbh ->prepare($sql);
    $sth->execute;
  }
  if (param('MMR 2')){
    $sql = qq!INSERT INTO immunizations 
(patient_id, administered_date, immunization_id) 
VALUES ('!.$patient_id.qq!','!.param('MMR 2').qq!','24')!;
    $sth = $dbh ->prepare($sql);
    $sth->execute;
  }

  #######################  Get List of Immunizations that have already been done ########
  $sql = qq!SELECT immunizations.administered_date, immunization.name 
FROM immunizations LEFT JOIN immunization ON immunizations.immunization_id=immunization.id 
WHERE immunizations.patient_id="$patient_id" ORDER BY administered_date!;
  $sth = $dbh->prepare($sql);
  $sth ->execute;
  while ($ref = $sth->fetch){
    $immunization_hash{@$ref[1]} = @$ref[0];
  }

  #####################################################  Print
  $immunizations =  qq!<table>!;
  $immunizations .= qq!<tr><td></td><th>Date</th><th>Recommendation</th>!;
  if ($page_name eq 'Update Record'){
    $immunizations .= qq!<th>Order</th>!;
  }
  $immunizations .= qq!</tr>!;

  #################################### Td ########################
  $immunizations .= qq!<tr><th>Tetanus-dipheria</th>!;
  if ($immunization_hash{'Td'}){
    $immunizations .= qq!<td>$immunization_hash{'Td'}</td>!;
    $immunizations .= qq!<td>Booster in !.($immunization_hash{'Td'}+10).qq!</td>!;
  } else {
    $immunizations .= qq!<td>No record</td>!;
    $immunizations .= qq!<td>Immunization</td>!;
  }
  if ($page_name eq 'Update Record'){
    $immunizations .= qq!<td><input type='text' name='Td' /></td>!;
  }
  $immunizations .= qq!</tr>!;


  #################################### flu #######################
  $immunizations .= qq!<tr><th >Influenza</th>!;
  if ($immunization_hash{'Influenza 1'}){
    $immunizations .= qq!<td>$immunization_hash{'Influenza 1'}</td>!;
    $immunizations .= qq!<td>Repeat in !.($immunization_hash{'Influenza 1'}+1).qq!</td>!;
  } else {
    $immunizations .= qq!<td>No record</td>!;
    if (todays_date()-$DOB>+65){
      $immunizations .= qq!<td>Immunization</td>!;
    } else {
      $immunizations .= qq!<td>No recommendation </td>!;
    }
  }
  if ($page_name eq 'Update Record'){
    $immunizations .= qq!<td><input type='text' name='Influenza 1' /></td>!;
  }
  $immunizations .= qq!</tr>!;

  ############################# Pneumovax ########################
  $immunizations .= qq!<tr><th >Pneumonia</th>!;
  if ($immunization_hash{'Pneumococcal Conjugate 1'}){
    $immunizations .= qq!<td>$immunization_hash{'Pneumococcal Conjugate 1'}</td>!;
    $immunizations .= qq!<td>Booster in !.($immunization_hash{'Pneumococcal Conjugate 1'}+7).qq!</td>!;
  } else {
    $immunizations .= qq!<td>No record</td>!;
    if (todays_date()-$DOB>=65){
      $immunizations .= qq!<td>Immunization</td>!;
    } else {
      $immunizations .= qq!<td>No recommendation </td>!;
    }
  }
  if ($page_name eq 'Update Record'){
    $immunizations .= qq!<td><input type='text' name='Pneumococcal Conjugate 1' /></td>!;
  }
  $immunizations .= qq!</tr>!;

  ################################# Hep B 1 ########################
  $immunizations .= qq!<tr><th >Hepatitis B 1</th>!;
  if ($immunization_hash{'Hepatitis B 1'}){
    $immunizations .= qq!<td>$immunization_hash{'Hepatitis B 1'}</td>!;
    unless ($immunization_hash{'Hepatitis B 2'}){
      $immunizations .= qq!<td>Second Immunization</td>!;
    }
  } else {
    $immunizations .= qq!<td>no record</td>!;
    $immunizations .= qq!<td>Immunization</td>!;
    if ($page_name eq 'Update Record' && !$immunization_hash{'Hepatitis B 2'}){
      $immunizations .= qq!<td><input type='text' name='Hepatitis B 1' /></td>!;
    }
  }
  $immunizations .= qq!</tr>!;

  ################### Hep B 2 ######################################
  if ($immunization_hash{'Hepatitis B 1'}){
    $immunizations .= qq!<tr><th >Hepatitis B 2</th>!;
    if ($immunization_hash{'Hepatitis B 2'}){
      $immunizations .= qq!<td>$immunization_hash{'Hepatitis B 2'}</td>!;
      unless($immunization_hash{'Hepatitis B 3'}){
	$immunizations .= qq!<td>Third Immunization</td>!;
      }
    } else {
      $immunizations .= qq!<td>No record</td><td>Second Immunization</td>!;
      if ($page_name eq 'Update Record' && !$immunization_hash{'Hepatitis B 3'}){
	$immunizations .= qq!<td><input type='text' name='Hepatitis B 2' /></td>!;
      }
    }
    $immunizations .= qq!</tr>!;
  }

  #################### Hep B 3 ####################################
  if ($immunization_hash{'Hepatitis B 2'}){
    $immunizations .= qq!<tr><th >Hepatitis B 3</th>!;
    if ($immunization_hash{'Hepatitis B 3'}){
      $immunizations .= qq!<td>$immunization_hash{'Hepatitis B 3'}</td><td></td>!;
    } else {
      $immunizations .= qq!<td>No record</td><td>Third Immunization</td>!;
      if ($page_name eq 'Update Record'){
	$immunizations .= qq!<td><input type='text' name='Hepatitis B 3' /></td>!;
      }
    }
    $immunizations .=qq!</tr>!;
  }

  ################################## Hep A 1 ########################
  $immunizations .= qq!<tr><th >Hepatitis A 1</th>!;
  if ($immunization_hash{'Hepatitis A 1'}){
    $immunizations .= qq!<td>$immunization_hash{'Hepatitis A 1'}</td>!;
    unless ($immunization_hash{'Hepatitis A 2'}){
      $immunizations .= qq!<td>Second Immunization</td>!
    } else {
	    $immunizations .= qq!<td></td>!;
	  }
  } else {
    $immunizations .= qq!<td>No record</td><td>Immunization</td>!;
    if ($page_name eq 'Update Record'  && !$immunization_hash{'Hepatitis A 2'}){
      $immunizations .= qq!<td><input type='text' name='Hepatitis A 1' /></td>!;
    }
  }
  $immunizations .= qq!</tr>!;

  ################################# Hep A 2 #########################
  if ($immunization_hash{'Hepatitis A 1'}){
    $immunizations .= qq!<tr><th >Hepatitis A 2</th>!;
    if ($immunization_hash{'Hepatitis A 2'}){
      $immunizations .= qq!<td>$immunization_hash{'Hepatitis A 2'}</td><td></td>!;
    } else {
      $immunizations .= qq!<td>No record</td><td>Second Immunization</td>!;
      if ($page_name eq 'Update Record'){
	$immunizations .= qq!<td><input type='text' name='Hepatitis A 2' /></td>!;
      }
    }
    $immunizations .= qq!</tr>!;
  }

  ################################### MMR 1 ########################
  $immunizations .= qq!<tr><th >MMR 1</th>!;
  if ($immunization_hash{'MMR 1'}){
    $immunizations .= qq!<td>$immunization_hash{'MMR 1'}</td>!;
    if (!$immunization_hash{'MMR 2'}){
      $immunizations .= qq!<td>Second Immunization</td>!;
    } else {
      $immunizations .= qq!<td></td>!;
    }
  } else {
    $immunizations .= qq!<td>No record</td><td>Immunization</td>!;
    if ($page_name eq 'Update Record' && !$immunization_hash{'MMR 2'}){
      $immunizations .= qq!<td><input type='text' name='MMR 1' /></td>!;
    }
  }
  $immunizations .= qq!</tr>!;


  ################################### MMR 2 ########################
  if ($immunization_hash{'MMR 1'}){
    $immunizations .= qq!<tr><th>MMR 2</th>!;
    if ($immunization_hash{'MMR 2'}){
      $immunizations .= qq!<td>$immunization_hash{'MMR 2'}</td><td></td>!;
    } else {
      $immunizations .= qq!<td>No record</td><td>Second Immunization</td>!;
      if ($page_name eq 'Update Record'){
	$immunizations .= qq!<td><input type='text' name='MMR 2' /></td>!;
      }
    }
    $immunizations .= qq!</tr>!;
  }
  $immunizations .= qq!</table>!;
  return $immunizations;
}


###########################################################################
##  Chronic Care Assessment
##  Passed:    Patient ID by parameter
##  Retruned:  Table of chronic care goals

sub Chronic_Care_Assessment {
  my $patient_id = shift;
  my ($sql, $sth, $sth2, $codes, $problem_id, %problem, @this_code, $index, @tests, $index2, @param_names, @Hgb_names, @Microalbuminuria_names, @Diabetic_eye_exam_names, @Diabetic_foot_exam_names, @Total_Cholesterol_names, @Triglyceride_names, @HDL_names, @LDL_names, @TSH_names, $c);
  my ($loinc_num, $date_ordered, $date_completed, $provider_id, $note);
  my $cca;

  ################ Get Problem List #######################################

  $sql = qq!SELECT DISTINCT code, problem_id  
            FROM problem_list LEFT JOIN icd_9_cm_concepts On problem_list.problem_id=icd_9_cm_concepts.id 
            WHERE patient_id='!.$patient_id.qq!'!;
  $sth = $dbh->prepare($sql);
  $sth -> execute;
  while (($codes, $problem_id) = $sth->fetchrow_array){$problem{$codes}=$problem_id;}

  ################ INSERT/UPDATE ##########################################

  @param_names = $cgi->param;
  @Hgb_names = grep(/HgbA1c date completed .*/, @param_names);
  @Microalbuminuria_names= grep(/Microalbuminuria date completed .*/, @param_names);
  @Diabetic_eye_exam_names= grep(/diabetic eye exam date completed .*/, @param_names);
  @Diabetic_foot_exam_names= grep(/diabetic foot exam date completed .*/, @param_names);
  @Total_Cholesterol_names=grep(/Total Cholesterol date completed .*/, @param_names);
  @Triglyceride_names=grep(/Triglyceride date completed .*/, @param_names);
  @HDL_names=grep(/HDL date completed .*/, @param_names);
  @LDL_names=grep(/LDL date completed .*/, @param_names);
  @TSH_names=grep(/TSH date completed .*/, @param_names);

  ################ HgA1c
  if (param('new HgbA1c date ordered')){
    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, !;
    if (param('new HgbA1c date completed')){$sql .= qq!date_completed, !;}
    $sql .= qq!provider_id, problem_id!;
    if (param('new HgbA1c note')){$sql .= qq!, note!;}
    $sql .= qq!) VALUES ('!.$patient_id.qq!', '17855-8', '!.param('new HgbA1c date ordered').qq!', !;
    if (param('new HgbA1c date completed')){
      $sql .= "'".param('new HgbA1c date completed')."', ";
    }
    $sql .= qq!'!.param('hidden_provider_id').qq!', '17572'!;
    if (param('new HgbA1c note')){
      $sql .= ", '".param('new HgbA1c note')."'";
    }
    $sql .= qq!)!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }
  for (@Hgb_names){
    if ($_=~/HgbA1c date completed (.*)/){$date_ordered=$1;}
    $sql = qq!UPDATE tests SET date_completed='!.param("HgbA1c date completed $date_ordered").qq!', note='!.param("HgbA1c note $date_ordered").qq!' WHERE patient_id='!.$patient_id.qq!' AND date_ordered="$date_ordered" AND loinc_num='17855-8'!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }

  ################ Microalbuminuria
  if (param('new microalbuminuria date ordered')){
    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, !;
    if (param('new microalbuminuria date completed')){$sql .= qq!date_completed, !;}
    $sql .= qq!provider_id, problem_id!;
    if (param('new microalbuminuria note')){$sql .= qq!, note!;}
    $sql .= qq!) VALUES ('!.$patient_id.qq!', '34535-5', '!.param('new microalbuminuria date ordered').qq!', !;
    if (param('new microalbuminuria date completed')){
      $sql .= "'".param('new microalbuminuria date completed')."', ";
    }
    $sql .= qq!'!.param('hidden_provider_id').qq!', '17572'!;
    if (param('new microalbuminuria note')){
      $sql .= ", '".param('new microalbuminuria note')."'";
    }
    $sql .= qq!)!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }
  for (@Microalbuminuria_names){
    if ($_=~/Mincroalbuminuria date completed (.*)/){$date_ordered=$1;}
     $sql = qq!UPDATE tests SET date_completed='!.param("Microalbuminuria date completed $date_ordered").qq!', note='!.param("Microalbuminuria note $date_ordered").qq!' WHERE patient_id='!.$patient_id.qq!' AND date_ordered="$date_ordered" AND loinc_num='34535-5'!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }

  ################ Diabetic Eye Exam
  if (param('new diabetic eye exam date ordered')){
    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, !;
    if (param('new diabetic eye exam date completed')){$sql .= qq!date_completed, !;}
    $sql .= qq!provider_id, problem_id!;
    if (param('new diabetic eye exam note')){$sql .= qq!, note!;}
    $sql .= qq!) VALUES ('!.$patient_id.qq!', '29271-4', '!.param('new diabetic eye exam date ordered').qq!', !;
    if (param('new diabetic eye exam date completed')){
      $sql .= "'".param('new diabetic eye exam date completed')."', ";
    }
    $sql .= qq!'!.param('hidden_provider_id').qq!', '17572'!;
    if (param('new diabetic eye exam note')){
      $sql .= ", '".param('new diabetic eye exam note')."'";
    }
    $sql .= qq!)!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }
  for (@Diabetic_eye_exam_names){
    if ($_=~/Mincroalbuminuria date completed (.*)/){$date_ordered=$1;}
     $sql = qq!UPDATE tests SET date_completed='!.param("Diabetic Eye Exam date completed $date_ordered").qq!', note='!.param("Diabetic Eye Exam note $date_ordered").qq!' WHERE patient_id='!.$patient_id.qq!' AND date_ordered="$date_ordered" AND loinc_num='29271-4'!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }

  ################ Diabetic Foot Exam
  if (param('new diabetic foot exam date ordered')){
    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, !;
    if (param('new diabetic foot exam date completed')){$sql .= qq!date_completed, !;}
    $sql .= qq!provider_id, problem_id!;
    if (param('new diabetic foot exam note')){$sql .= qq!, note!;}
    $sql .= qq!) VALUES ('!.$patient_id.qq!', '11428-0', '!.param('new diabetic foot exam date ordered').qq!', !;
    if (param('new diabetic foot exam date completed')){
      $sql .= "'".param('new diabetic foot exam date completed')."', ";
    }
    $sql .= qq!'!.param('hidden_provider_id').qq!', '17572'!;
    if (param('new diabetic foot exam note')){
      $sql .= ", '".param('new diabetic foot exam note')."'";
    }
    $sql .= qq!)!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }
  for (@Diabetic_foot_exam_names){
    if ($_=~/diabetic foot exam date completed (.*)/){$date_ordered=$1;}
     $sql = qq!UPDATE tests SET date_completed='!.param("diabetic Foot Exam date completed $date_ordered").qq!', note='!.param("diabetic Foot Exam note $date_ordered").qq!' WHERE patient_id='!.$patient_id.qq!' AND date_ordered="$date_ordered" AND loinc_num='11428-0'!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }


  ################ LIPIDS

  ##### Total Cholesterol
  if (param('new_total_cholesterol_date_ordered')){
    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, !;
    if (param('new total cholesterol date completed')){$sql .= qq!date_completed, !;}
    $sql .= qq!provider_id, problem_id!;
    if (param('new total cholesterol note')){$sql .= qq!, note!;}
    $sql .= qq!) VALUES ('!.$patient_id.qq!', '35200-5', '!.param('new_total_cholesterol_date_ordered').qq!', !;
    if (param('new total cholesterol date completed')){
      $sql .= "'".param('new total cholesterol date completed')."', ";
    }
    $sql .= qq!'!.param('hidden_provider_id').qq!', '!;
    @this_code = ();
    @this_code = grep(/250|790\.2|428|272/, keys %problem);
    $sql .= $problem{$this_code[0]}.qq!'!;
    if (param('new total cholesterol note')){
      $sql .= ", '".param('new total cholesterol note')."'";
    }
    $sql .= qq!)!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }
  for (@Total_Cholesterol_names){
    if ($_=~/Total Cholesterol date completed (.*)/){$date_ordered=$1;}
     $sql = qq!UPDATE tests SET date_completed='!.param("Total Cholesterol date completed $date_ordered").qq!', note='!.param("Total Cholesterol note $date_ordered").qq!' WHERE patient_id='!.$patient_id.qq!' AND date_ordered="$date_ordered" AND loinc_num='35200-5'!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }

  ###### Triglyceride
  if (param('new_triglyceride_date_ordered')){
    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, !;
    if (param('new triglyceride date completed')){$sql .= qq!date_completed, !;}
    $sql .= qq!provider_id, problem_id!;
    if (param('new triglyceride note')){$sql .= qq!, note!;}
    $sql .= qq!) VALUES ('!.$patient_id.qq!', '35217-9', '!.param('new_triglyceride_date_ordered').qq!', !;
    if (param('new triglyceride date completed')){
      $sql .= "'".param('new triglyceride date completed')."', ";
    }
    $sql .= qq!'!.param('hidden_provider_id').qq!', '!;
    @this_code = ();
    @this_code = grep(/250|790\.2|428|272/, keys %problem);
    $sql .= $problem{$this_code[0]}.qq!'!;
    if (param('new triglyceride note')){
      $sql .= ", '".param('new triglyceride note')."'";
    }
    $sql .= qq!)!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }
  for (@Triglyceride_names){
    if ($_=~/Triglyceride date completed (.*)/){$date_ordered=$1;}
     $sql = qq!UPDATE tests SET date_completed='!.param("Triglyceride date completed $date_ordered").qq!', note='!.param("Triglyceride note $date_ordered").qq!' WHERE patient_id='!.$patient_id.qq!' AND date_ordered="$date_ordered" AND loinc_num='35217-9'!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }

  ##### HDL
  if (param('new_hdl_date_ordered')){
    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, !;
    if (param('new hdl date completed')){$sql .= qq!date_completed, !;}
    $sql .= qq!provider_id, problem_id!;
    if (param('new hdl note')){$sql .= qq!, note!;}
    $sql .= qq!) VALUES ('!.$patient_id.qq!', '35197-3', '!.param('new_hdl_date_ordered').qq!', !;
    if (param('new hdl date completed')){
      $sql .= "'".param('new hdl date completed')."', ";
    }
    $sql .= qq!'!.param('hidden_provider_id').qq!', '!;
    @this_code = ();
    @this_code = grep(/250|790\.2|428|272/, keys %problem);
    $sql .= $problem{$this_code[0]}.qq!'!;
    if (param('new hdl note')){
      $sql .= ", '".param('new hdl note')."'";
    }
    $sql .= qq!)!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }
  for (@HDL_names){
    if ($_=~/Hdl date completed (.*)/){$date_ordered=$1;}
     $sql = qq!UPDATE tests SET date_completed='!.param("HDL date completed $date_ordered").qq!', note='!.param("HDL note $date_ordered").qq!' WHERE patient_id='!.$patient_id.qq!' AND date_ordered="$date_ordered" AND loinc_num='35197-3'!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }

  ##### LDL
  if (param('new_ldl_date_ordered')){
    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, !;
    if (param('new ldl date completed')){$sql .= qq!date_completed, !;}
    $sql .= qq!provider_id, problem_id!;
    if (param('new ldl note')){$sql .= qq!, note!;}
    $sql .= qq!) VALUES ('!.$patient_id.qq!', '35198-1', '!.param('new_ldl_date_ordered').qq!', !;
    if (param('new ldl date completed')){
      $sql .= "'".param('new ldl date completed')."', ";
    }
    $sql .= qq!'!.param('hidden_provider_id').qq!', '!;
    @this_code = ();
    @this_code = grep(/428|250|790\.2|272/, keys %problem);
    $sql .= $problem{$this_code[0]}.qq!'!;
    if (param('new ldl note')){
      $sql .= ", '".param('new ldl note')."'";
    }
    $sql .= qq!)!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }
  for (@LDL_names){
    if ($_=~/Ldl date completed (.*)/){$date_ordered=$1;}
     $sql = qq!UPDATE tests SET date_completed='!.param("LDL date completed $date_ordered").qq!', note='!.param("LDL note $date_ordered").qq!' WHERE patient_id='!.$patient_id.qq!' AND date_ordered="$date_ordered" AND loinc_num='35198-1'!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }

  ################ TSH
  if (param('new TSH date ordered')){
    $sql = qq!INSERT into tests (patient_id, loinc_num, date_ordered, !;
    if (param('new TSH date completed')){$sql .= qq!date_completed, !;}
    $sql .= qq!provider_id, problem_id!;
    if (param('new TSH note')){$sql .= qq!, note!;}
    $sql .= qq!) VALUES ('!.$patient_id.qq!', '3016-3', '!.param('new TSH date ordered').qq!', !;
    if (param('new TSH date completed')){
      $sql .= "'".param('new TSH date completed')."', ";
    }
    $sql .= qq!'!.param('hidden_provider_id').qq!', '!;
    @this_code = ();
    @this_code = grep(/428|243|244/, keys %problem);
    $sql .= $problem{$this_code[0]}.qq!'!;
    if (param('new TSH note')){
      $sql .= ", '".param('new TSH note')."'";
    }
    $sql .= qq!)!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }
  for (@TSH_names){
    if ($_=~/TSH date completed (.*)/){$date_ordered=$1;}
    $sql = qq!UPDATE tests SET date_completed='!.param("TSH date completed $date_ordered").qq!', note='!.param("TSH note $date_ordered").qq!' WHERE patient_id='!.$patient_id.qq!' AND date_ordered="$date_ordered" AND loinc_num='3016-3'!;
    $sth=$dbh->prepare($sql);
    $sth->execute;
  }

  ################ PRINT ##################################################
  $cca = qq!<table><caption><b>Chronic Care Assessment</b></caption>!;
  if ($page_name ne 'Patient File'){
    $cca .= qq!<tr align='RIGHT'><td></td><th>Date Ordered</th><th>Date Completed</th><th>Result</th></tr>!;
  } else {
    $cca .= qq!<tr align='RIGHT'><td></td><th>Date Ordered</th><th>Result</th></tr>!;
  }
  $dbh2 = DBI->connect(
		       $dbase,
		       param('User'),
		       param('Password')
		      ) or die(print $cgi->header(), "Error connecting to Database");
  
  #################### Diabetes #####################
  @this_code=();
  if ( @this_code = grep (/250|790\.2/, keys %problem)){
    @tests=();
    $sql = qq!SELECT loinc_num, date_ordered, date_completed, note 
              FROM tests 
	      WHERE patient_id='!.$patient_id.qq!' ORDER BY date_ordered!;
    $sth2 = $dbh2->prepare($sql);
    $sth2->execute;
    $sth2->bind_columns(\($loinc_num, $date_ordered, $date_completed, $note));
    while ($sth2->fetch){push (@tests, [$loinc_num, $date_ordered, $date_completed, $note]);}
    
    ##### HgbA1c
    unless ($cca =~/HgbA1c/){$cca .= qq!<tr><th>HgbA1c</th></tr>!;}
    for ($index2=0; $index2<=$#tests; $index2++){
      if ($tests[$index2][0] eq '17855-8'){
	$cca .= qq!<tr align='RIGHT'><td></td><td>$tests[$index2][1]</td>!;
	if ($tests[$index2][3]){
	  if ($page_name ne 'Patient File'){
	    $cca .= qq!<td>$tests[$index2][2]</td>!;
	    if ($tests[$index2][3]>7.0){$cca .= qq!<td><em>$tests[$index2][3]</em></td>!;}
	    else {$cca.=qq!<td>$tests[$index2][3]</td>!;}
	  } else {
	    if ($tests[$index2][3]>7.0){$cca .= qq!<td><em>$tests[$index2][3]</em></td>!;}
	    else {$cca.=qq!<td>$tests[$index2][3]</td>!;}
	  }
	} elsif ($page_name eq 'Update Record'){
	  $cca .= qq!<td><input type='text' name="HgbA1c date completed $tests[$index2][1]" /></td><td><input type='text' name="HgbA1c note $tests[$index2][1]" /></td>!;
	}elsif (($page_name eq 'Patient File')||($page_name eq 'New Encounter')|| ($page_name eq 'Main Screen')) {
	  $cca.= qq!<td>Pending</td>!;
	}
	$cca .= qq!</tr>!;
      }
    }
    if ($page_name eq 'Update Record'){
      $cca .= qq!<tr><td></td><td><input type='text' name='new HgbA1c date ordered' /></td><td><input type='text' name='new HgbA1c date completed' /></td><td><input type='text' name='new HgbA1c note' /></td></tr>!;
    }
    
    ##### Microalbuminuria
    unless ($cca=~/Urinary Microalbumin/){$cca .= qq!<tr><th>Urinary Microalbumin</th>!;}
    for ($index2=0; $index2<=$#tests; $index2++){
      if ($tests[$index2][0] eq '34535-5'){
	$cca .= qq!<tr align='RIGHT'><td></td><td>$tests[$index2][1]</td>!;
	if ($tests[$index2][3]){
	  if ($page_name ne 'Patient File'){
	    $cca .= qq!<td>$tests[$index2][2]</td>!;
	    if ($tests[$index2][3]>30){$cca .= qq!<td><em>$tests[$index2][3]</em></td>!;}
	    else {$cca.=qq!<td>$tests[$index2][3]</td>!;}

	  } else {
	    if ($tests[$index2][3]>30){$cca .= qq!<td><em>$tests[$index2][3]</em></td>!;}
	    else {$cca.=qq!<td>$tests[$index2][3]</td>!;}
	  }
	} elsif (($page_name eq 'Patient File')||($page_name eq 'New Encounter')|| ($page_name eq 'Main Screen')) {
	  $cca.= qq!<td>Pending</td>!;
	} elsif ($page_name eq 'Update Record') {
	  $cca .= qq!<td><input type='text' name="Microalbuminuria date completed $tests[$index2][1]" /></td><td><input type='text' name="Microalbuminuria note $tests[$index2][1]" /></td>!;
	}
	$cca .= qq!</tr>!;
      }
    }
    if ($page_name eq 'Update Record'){
      $cca .= qq!<tr><td></td><td><input type='text' name='new microalbuminuria date ordered' /></td><td><input type='text' name='new microalbuminuria date completed' /></td><td><input type='text' name='new microalbuminuria note' /></td></tr>!;
    }
    
  ##### Diabetic Eye Exam
    unless ($cca=~/Diabetic Eye Exam/){$cca .= qq!<tr><th>Diabetic Eye Exam</th>!;}
    for ($index2=0; $index2<=$#tests; $index2++){
      if ($tests[$index2][0] eq '29271-4'){
	$cca .= qq!<tr align='RIGHT'><td></td><td>$tests[$index2][1]</td>!;
	if ($tests[$index2][3]){
	  if ($page_name ne 'Patient File'){
	    $cca .= qq!<td>$tests[$index2][2]</td>!;
	    if ($tests[$index2][3]>30){$cca .= qq!<td><em>$tests[$index2][3]</em></td>!;}
	    else {$cca.=qq!<td>$tests[$index2][3]</td>!;}

	  } else {
	    if ($tests[$index2][3]>30){$cca .= qq!<td><em>$tests[$index2][3]</em></td>!;}
	    else {$cca.=qq!<td>$tests[$index2][3]</td>!;}
	  }
	} elsif (($page_name eq 'Patient File')||($page_name eq 'New Encounter')|| ($page_name eq 'Main Screen')) {
	  $cca.= qq!<td>Pending</td>!;
	} elsif ($page_name eq 'Update Record') {
	  $cca .= qq!<td><input type='text' name="diabetic eye exam date completed $tests[$index2][1]" /></td><td><input type='text' name="diabetic eye exam note $tests[$index2][1]" /></td>!;
	}
	$cca .= qq!</tr>!;
      }
    }
    if ($page_name eq 'Update Record'){
      $cca .= qq!<tr><td></td><td><input type='text' name='new diabetic eye exam date ordered' /></td><td><input type='text' name='new diabetic eye exam date completed' /></td><td><input type='text' name='new diabetic eye exam note' /></td></tr>!;
    }

  ##### Diabetic Foot Exam
    unless ($cca=~/Diabetic Foot Exam/){$cca .= qq!<tr><th>Diabetic Foot Exam</th>!;}
    for ($index2=0; $index2<=$#tests; $index2++){
      if ($tests[$index2][0] eq '11428-0'){
	$cca .= qq!<tr align='RIGHT'><td></td><td>$tests[$index2][1]</td>!;
	if ($tests[$index2][3]){
	  if ($page_name ne 'Patient File'){
	    $cca .= qq!<td>$tests[$index2][2]</td>!;
	    if ($tests[$index2][3]>30){$cca .= qq!<td><em>$tests[$index2][3]</em></td>!;}
	    else {$cca.=qq!<td>$tests[$index2][3]</td>!;}

	  } else {
	    if ($tests[$index2][3]>30){$cca .= qq!<td><em>$tests[$index2][3]</em></td>!;}
	    else {$cca.=qq!<td>$tests[$index2][3]</td>!;}
	  }
	} elsif (($page_name eq 'Patient File')||($page_name eq 'New Encounter')|| ($page_name eq 'Main Screen')) {
	  $cca.= qq!<td>Pending</td>!;
	} elsif ($page_name eq 'Update Record') {
	  $cca .= qq!<td><input type='text' name="diabetic foot exam date completed $tests[$index2][1]" /></td><td><input type='text' name="diabetic foot exam note $tests[$index2][1]" /></td>!;
	}
	$cca .= qq!</tr>!;
      }
    }
    if ($page_name eq 'Update Record'){
      $cca .= qq!<tr><td></td><td><input type='text' name='new diabetic foot exam date ordered' /></td><td><input type='text' name='new diabetic foot exam date completed' /></td><td><input type='text' name='new diabetic foot exam note' /></td></tr>!;
    }
  }
  
  ########################## Lipids
  @this_code=();
  if (@this_code = grep (/428|250|790\.2|272/, keys %problem)){
    unless ($cca=~/Lipids/){$cca .= qq!<tr><th>Lipids</th></tr>!;}

    ##### Total Cholesterol
    @tests = ();
    $sql = qq!SELECT date_ordered, date_completed, provider_id, note 
              FROM tests 
	      WHERE patient_id='!.$patient_id.qq!' AND loinc_num='35200-5' ORDER BY date_ordered!;
    $sth2 = $dbh2->prepare($sql);
    $sth2->execute;
    $sth2->bind_columns(\($date_ordered, $date_completed, $provider_id, $note));
    while ($sth2->fetch){push (@tests, [$date_ordered, $date_completed, $provider_id, $note]);}

    for ($index2=0; $index2<=$#tests; $index2++){
      if ($index2==0){
	$cca .= qq!<tr align='Right'><td>Total cholesterol</td><td>$tests[$index2][0]</td>!;
      } else {
	$cca .= qq!<tr align='Right'><td></td><td>$tests[$index2][0]</td>!;
      }
      if ($tests[$index2][3]){
	if ($page_name ne 'Patient File'){
	  $cca .= qq!<td>$tests[$index2][1]</td>!;
	  if ($tests[$index2][3]>200){$cca .= qq!<td><em>$tests[$index2][3]</em></td>!;}
	  else {$cca .= qq!<td>$tests[$index2][3]</td>!;}
	} else {
	  if ($tests[$index2][3]>200){$cca .= qq!<td><em>$tests[$index2][3]</em></td>!;}
	  else {$cca .= qq!<td>$tests[$index2][3]</td>!;}
	}
      } elsif (($page_name eq 'Patient File')||($page_name eq 'New Encounter')|| ($page_name eq 'Main Screen')) {
	$cca.= qq!<td>Pending</td>!;
      } elsif ($page_name eq 'Update Record') {
	$cca .= qq!<td><input type='text' name="Total Cholesterol date completed $tests[$index2][0]" onblur="CholesterolCompleted(this)" /></td><td><input type='text' name="Total Cholesterol note $tests[$index2][0]" /></td>!;
      }
      $cca .= qq!</tr>!;
    }
    $cca .= qq!<tr><td></td><td colspan=8><hr></td></tr>!;
    
    ##### Triglyceride
    @tests = ();
    $sql = qq!SELECT date_ordered, date_completed, provider_id, note 
              FROM tests 
	      WHERE patient_id='!.$patient_id.qq!' AND loinc_num='35217-9' ORDER BY date_ordered!;
    $sth2 = $dbh2->prepare($sql);
    $sth2->execute;
    $sth2->bind_columns(\($date_ordered, $date_completed, $provider_id, $note));
    while ($sth2->fetch){push (@tests, [$date_ordered, $date_completed, $provider_id, $note]);}

    for ($index2=0; $index2<=$#tests; $index2++){
      if ($index2==0){
	$cca .= qq!<tr align='Right'><td>Triglycerides</td><td>$tests[$index2][0]</td>!;
      } else {
	$cca .= qq!<tr align='Right'><td></td><td>$tests[$index2][0]</td>!;
      }
      if ($tests[$index2][3]){
	if ($page_name ne 'Patient File'){
	  $cca .= qq!<td>$tests[$index2][1]</td>!;
	  if ($tests[$index2][3]>200){$cca .= qq!<td><em>$tests[$index2][3]</em></td>!;}
	  else {$cca.=qq!<td>$tests[$index2][3]</td>!;}
	} else {
	    if ($tests[$index2][3]>200){$cca .= qq!<td><em>$tests[$index2][3]</em></td>!;}
	    else {$cca.=qq!<td>$tests[$index2][3]</td>!;}
	}
      } elsif (($page_name eq 'Patient File')||($page_name eq 'New Encounter')|| ($page_name eq 'Main Screen')) {
	$cca.= qq!<td>Pending</td>!;
      } elsif ($page_name eq 'Update Record') {
	$cca .= qq!<td><input type='text' name="Triglyceride date completed $tests[$index2][0]" /></td><td><input type='text' name="Triglyceride note $tests[$index2][0]" /></td>!;
      }
      $cca .= qq!</tr>!;
    }
    $cca .= qq!<tr><td></td><td colspan=8><hr></td></tr>!;

    #####  HDL
    @tests = ();
    $sql = qq!SELECT date_ordered, date_completed, provider_id, note 
              FROM tests 
	      WHERE patient_id='!.$patient_id.qq!' AND loinc_num='35197-3' ORDER BY date_ordered!;
    $sth2 = $dbh2->prepare($sql);
    $sth2->execute;
    $sth2->bind_columns(\($date_ordered, $date_completed, $provider_id, $note));
    while ($sth2->fetch){push (@tests, [$date_ordered, $date_completed, $provider_id, $note]);}

    for ($index2=0; $index2<=$#tests; $index2++){
      if ($index2==0){
	$cca .= qq!<tr align='Right'><td>HDL</td><td>$tests[$index2][0]</td>!;
      } else {
	$cca .= qq!<tr align='Right'><td></td><td>$tests[$index2][0]</td>!;
      }
	if ($tests[$index2][3]){
	  if ($page_name ne 'Patient File'){
	    $cca .= qq!<td>$tests[$index2][1]</td><td> $tests[$index2][3]</td>!;
	  } else {
	    $cca .= qq!<td>$tests[$index2][3]</td>!;
	  }
	} elsif (($page_name eq 'Patient File')||($page_name eq 'New Encounter')|| ($page_name eq 'Main Screen')) {
	  $cca.= qq!<td>Pending</td>!;
	} elsif ($page_name eq 'Update Record') {
	  $cca .= qq!<td><input type='text' name="HDL date completed $tests[$index2][0]" /></td><td><input type='text' name="HDL note $tests[$index2][0]" /></td>!;
	}
      $cca .= qq!</tr>!;
    }
    $cca .= qq!<tr><td></td><td colspan=8><hr></td></tr>!;

    ##### LDL
    @tests = ();
    $sql = qq!SELECT date_ordered, date_completed, provider_id, note 
              FROM tests 
	      WHERE patient_id='!.$patient_id.qq!' AND loinc_num='35198-1' ORDER BY date_ordered!;
    $sth2 = $dbh2->prepare($sql);
    $sth2->execute;
    $sth2->bind_columns(\($date_ordered, $date_completed, $provider_id, $note));
    while ($sth2->fetch){push (@tests, [$date_ordered, $date_completed, $provider_id, $note]);}

    for ($index2=0; $index2<=$#tests; $index2++){
      if ($index2==0){
	$cca .= qq!<tr align='Right'><td>LDL</td><td>$tests[$index2][0]</td>!;
      } else {
	$cca .= qq!<tr align='Right'><td></td><td>$tests[$index2][0]</td>!;
      }
      if ($tests[$index2][3]){
	  if ($page_name ne 'Patient File'){
	    $cca .= qq!<td>$tests[$index2][1]</td>!;
	    if ($tests[$index2][3]>100){$cca .= qq!<td><em>$tests[$index2][3]</em></td>!;}
	    else {$cca.=qq!<td>$tests[$index2][3]</td>!;}
	  } else {
	    if ($tests[$index2][3]>100){$cca .= qq!<td><em>$tests[$index2][3]</em></td>!;}
	    else {$cca.=qq!<td>$tests[$index2][3]</td>!;}
	  }
      } elsif (($page_name eq 'Patient File')||($page_name eq 'New Encounter')|| ($page_name eq 'Main Screen')) {
	$cca.= qq!<td>Pending</td>!;
      } elsif ($page_name eq 'Update Record') {
	$cca .= qq!<td><input type='text' name="LDL date completed $tests[$index2][0]" /></td><td><input type='text' name="LDL note $tests[$index2][0]" /></td>!;
      }
      $cca .= qq!</tr>!;
    }
    $cca .= qq!<tr><td></td><td colspan=8><hr></td></tr>!;

    if ($page_name eq 'Update Record'){
      $cca .= qq!
<tr align='Right'><td>Total Cholesterol</td><td><input type='text' name='new_total_cholesterol_date_ordered' onblur="CholesterolOrdered(this)" /></td><td><input type='text' name='new total cholesterol date completed' onblur="CholesterolCompleted(this)" /></td><td><input type='text' name='new total cholesterol note' /></td></tr>
<tr align='Right'><td>Triglycerides</td><td><input type='text' name='new_triglyceride_date_ordered' ID='trig_ordered' /></td><td><input type='text' name='new triglyceride date completed' ID='trig_completed' /></td><td><input type='text' name='new triglyceride note' /></td></tr>
<tr align='Right'><td>HDL</td><td><input type='text' name='new_hdl_date_ordered'  ID='hdl_ordered' /></td><td><input type='text' name='new hdl date completed' ID='hdl_completed' /></td><td><input type='text' name='new hdl note' /></td></tr>
<tr align='Right'><td>LDL</td><td><input type='text' name='new_ldl_date_ordered'  ID='ldl_ordered' /></td><td><input type='text' name='new ldl date completed' ID='ldl_completed' /></td><td><input type='text' name='new ldl note' /></td></tr>
!;
    }
  }
  
  #################### Thyroid ################
  @this_code = ();
  if (@this_code = grep (/428|243|244/, keys %problem)){
    @tests=();
    $sql = qq!SELECT loinc_num, date_ordered, date_completed, note 
              FROM tests 
	      WHERE patient_id='!.$patient_id.qq!' AND problem_id='!.$problem{$this_code[0]}.qq!' ORDER BY date_ordered!;
    $sth2 = $dbh2->prepare($sql);
    $sth2->execute;
    $sth2->bind_columns(\($loinc_num, $date_ordered, $date_completed, $note));
    while ($sth2->fetch){push (@tests, [$loinc_num, $date_ordered, $date_completed, $note]);}
    
    ##### TSH
    unless ($cca =~/TSH/){$cca .= qq!<tr><th>TSH</th></tr>!;}
    for ($index2=0; $index2<=$#tests; $index2++){
      if ($tests[$index2][0] eq '3016-3'){
	$cca .= qq!<tr aligh='LEFT'><td></td><td>$tests[$index2][1]</td>!;
	if ($tests[$index2][3]){
	  if ($page_name ne 'Patient File'){
	    $cca .= qq!<td>$tests[$index2][2]</td><td> $tests[$index2][3]</td>!;
	  }else {
	    $cca .= qq!<td>$tests[$index2][3]</td>!;
	  }
	} elsif ($page_name eq 'Update Record'){
	  $cca .= qq!<td><input type='text' name="TSH date completed $tests[$index2][1]" /></td><td><input type='text' name="TSH note $tests[$index2][1]" /></td>!;
	}elsif (($page_name eq 'Patient File')||($page_name eq 'New Encounter')|| ($page_name eq 'Main Screen')) {
	  $cca.= qq!<td>Pending</td>!;
	}
	$cca .= qq!</tr>!;
      }
    }
    if ($page_name eq 'Update Record'){
      $cca .= qq!<tr><td></td><td><input type='text' name='new TSH date ordered' /></td><td><input type='text' name='new TSH date completed' /></td><td><input type='text' name='new TSH note' /></td></tr>!;
    }
    
  }
  #################### CHF #####################
  @this_code=();
  if (@this_code = grep (/428/, keys %problem)){
    @tests=();
    $sql = qq!SELECT loinc_num, date_ordered, date_completed, note 
              FROM tests 
	      WHERE patient_id='!.$patient_id.qq!' AND problem_id='!.$problem{$this_code[0]}.qq!' ORDER BY date_ordered!;
    $sth2 = $dbh2->prepare($sql);
    $sth2->execute;
    $sth2->bind_columns(\($loinc_num, $date_ordered, $date_completed, $note));
    while ($sth2->fetch){push (@tests, [$loinc_num, $date_ordered, $date_completed, $note]);}
    
    $cca .=	qq!<tr><th>ASA</th><td>--</td></tr>
	           <tr><th>ACE-inhibitor</th><td>--</td></tr>
	           <tr><th>Beta-block</th><td>--</td></tr>
		   <tr><th>Statin</th><td>--</td></tr>
		   <tr><th>Spironolactone</th><td>--</td></tr>!;
  }
  #################### Asthma #####################
  @this_code=();
  if (@this_code = grep(/493/, %problem)){
    @tests=();
    $sql = qq!SELECT loinc_num, date_ordered, date_completed, note 
              FROM tests 
	      WHERE patient_id='!.$patient_id.qq!' AND problem_id='!.$problem{$this_code[0]}.qq!' ORDER BY date_ordered!;
    $sth2 = $dbh2->prepare($sql);
    $sth2->execute;
    $sth2->bind_columns(\($loinc_num, $date_ordered, $date_completed, $note));
    while ($sth2->fetch){push (@tests, [$loinc_num, $date_ordered, $date_completed, $note]);}
  }
  #################### Depression #####################
  @this_code=();
  if (@this_code = grep (/296|311/, %problem)){
    @tests=();
    $sql = qq!SELECT loinc_num, date_ordered, date_completed, note 
              FROM tests 
	      WHERE patient_id='!.$patient_id.qq!' AND problem_id='!.$problem{$this_code[0]}.qq!' ORDER BY date_ordered!;
    $sth2 = $dbh2->prepare($sql);
    $sth2->execute;
    $sth2->bind_columns(\($loinc_num, $date_ordered, $date_completed, $note));
    while ($sth2->fetch){push (@tests, [$loinc_num, $date_ordered, $date_completed, $note]);}
    
  }
  
  $cca .= qq!</table>!;
  return $cca;
}

##############################################################################
##  Past Problems
##  Passed:   Patient ID by paramater
##  Returned: Array of Array:  @past, @chronic, @ongoing, @acute

sub Past_Problems {
  my $patient_id = shift;
  my (@past, @chronic, @ongoing, @acute);
  my ($problem_id, $concept, $code, $date_added, $active, $chronic, $sql, $sth);
  $sql   = qq!SELECT problem_id, concept, code, date_added, active, chronic 
FROM problem_list LEFT JOIN icd_9_cm_concepts ON problem_list.problem_id=icd_9_cm_concepts.id 
WHERE patient_id="!.$patient_id.qq!"!;
  $sth = $dbh->prepare($sql);
  $sth ->execute;
  $sth ->bind_columns(\($problem_id, $concept, $code, $date_added, $active, $chronic));
  while ($sth->fetch){
    $concept =~s/(.*)\[.*\]/$1/;
    if ($chronic == 3){
      push(@past, [$problem_id, $concept, $code, $date_added, $active, $chronic]);
    }
    if ($chronic == 2){
      push(@chronic, [$problem_id, $concept, $code, $date_added, $active, $chronic]);
    }
    if ($chronic == 1){
      push(@ongoing, [$problem_id, $concept, $code, $date_added, $active, $chronic]);
    }
    if ($chronic == 0){
      push(@acute, [$problem_id, $concept, $code, $date_added, $active, $chronic]);
    }
  }
  return (\@past, \@chronic, \@ongoing, \@acute);
}

###################################################################################
##  Reports
##  
##  

sub Reports {

  my $patient_id = shift;
  my ($sql, $sth, $title, $fname, $lname, $DOB, $date_ordered, $date_completed, $delay, $report, $y, $z, $k, $Denominator, $lessSeven, $sevenNine, $nineEleven, $moreEleven, $less70, $SeventyToOneHundred, $OneHundredToOneThirty, $OneThirtyToOneSixty, $OneSixtyToOneNinety, $more190, $NotCalculated, $Missing, $svg, $note, @tests, @totalCholesterol, @triglycerides, @HDL, @LDL, $index, $codes, $problem_id, %problem, $date, $Blood_pressure, $systolic, $diastolic);
  unless(param('SubmitButton')){

    $sql   = "SELECT title, fname, lname, DOB 
FROM patient_data 
WHERE pid='".$patient_id."'";
    $sth   = $dbh->prepare($sql);
    $sth   ->execute;
    $sth   ->bind_columns(\($title, $fname, $lname, $DOB));
    $sth->fetch;

    open (OUTFILE, ">/usr/local/apache2/htdocs/temp.svg");
    $svg = qq|<?xml version="1.0" encoding="iso-8859-1"?>
            <!DOCTYPE svg PUBLIC "-//W3C//DTD SVG 20001102//EN"
             "http://www.w3.org/TR/2000/CR-SVG-20001102/DTD/svg-2001102.dtd">
            <?xml-stylesheet type="text/css" href="http://localhost/svgStylesheet.css" ?>
            <svg width="800" height="3000" xmlns:xlink="http://www.w3.org/1999/xlink"> 
	      <defs>
		<pattern id="gridPattern" 
		         width="20" height="20"
		         patternUnits="userSpaceOnUse">
		    <rect class="gridBox" x="0" y="0" width="20" height="20" />
	        </pattern>
		<linearGradient id="redOpacity" gradientTransform="rotate(90)">
		    <stop offset="0%" stop-color="red" stop-opacity="1" />
		    <stop offset="100%" stop-color="red" stop-opacity=".3" />
		</linearGradient>
		<rect class="marker" id="lineBox" x="-5" y="-5" width="10" height="10" />
		<polygon class="marker" id="triangleBox" points="-5,-5 5,-5 0,7" />
	      </defs>

<g transform="translate(160, 25)">
     <text x="0" y="0" font-size="24" fill-opacity="1" font-family="New Times Roman" fill="black">
     Report on $title $fname $lname
     </text>
</g>

|;

    $svg .= qq|<!-- ##############  Diabetes ############# -->|;

    $sql = qq!SELECT DISTINCT code, problem_id  
            FROM problem_list LEFT JOIN icd_9_cm_concepts On problem_list.problem_id=icd_9_cm_concepts.id 
            WHERE patient_id='!.$patient_id.qq!'!;
    $sth = $dbh->prepare($sql);
    $sth -> execute;
    while (($codes, $problem_id) = $sth->fetchrow_array){$problem{$codes}=$problem_id;}
    
    if ( grep (/250|790\.2/, keys %problem)){

      $svg .= qq|
<!-- *** Diabetes: render background grid *** -->
<g transform="translate(80,30)">
  <rect x="0" y="0" width="400" height="280" fill="url(#gridPattern)"  />
  <rect x="0" y="0" width="400" height="240" fill="url(#redOpacity)" />
  <rect x="0" y="240" width="400" height="20" fill="yellow" opacity=".3" />
  <rect x="0" y="260" width="400" height="20" fill="green" opacity=".3" />
</g>

<!-- *** Diabetes: text label (vertical axis) *** -->
<g transform="translate(30,300)">
  <text id="verticalLabel" x="20" y="0" 
        transform="rotate(-90)"
        fill="black" 
        font-size="24">
          HgbA1c
  </text>
  <text x="490" y="-200" fill="black" font-size="24">
    HgbA1c
  </text>
  <circle cx="475" cy="-210" r="5" stroke="black" fill="none" stroke-width="2" />
</g>|;

$svg .= qq|<!-- *** Diabetes: unit label (vertical axis) *** -->|;
for ($index=0; $index<15; $index++){
$svg .= qq|<g transform="translate(50,|.(320-(20*$index)).qq|)">
  <text id="horizontalLabel" x="0" y="0" 
        fill="blue" fill-opacity="1" 
        font-size="18">|.($index+5).qq|
  </text>
  </g>|;
}

$svg .= qq|<!-- *** Diabetes: text label (horizontal axis) *** -->
<g transform="translate(160,425)">
  <text id="horizontalLabel" x="0" y="0" 
        fill="black" fill-opacity="1" 
        font-size="24">
        Date
  </text>
</g>

<!-- *** Diabetes: unit label (horizontal axis) *** -->
|;

  $sql = qq!SELECT date_completed, note 
              FROM tests 
	      WHERE patient_id='!.$patient_id.qq!' AND loinc_num="17855-8" ORDER BY date_ordered!;
  $sth = $dbh->prepare($sql);
  $sth->execute;
  $sth->bind_columns(\($date_completed, $note));
@tests = ();
  while ($sth->fetch){push (@tests, [$date_completed, $note]);}
  for ($index=0; $index<=$#tests; $index++){
    if ($tests[$index][1]){
      $svg .= qq|<g transform="translate(|.(80+20*$index).qq|,400)">
                 <text id="horizontalLabel" x="0" y="0"
                       transform="rotate(-90)"
                       fill="blue" fill-opacity="1" 
                       font-size="18">$tests[$index][0]</text>
               </g>|;
    }
  }

$svg .= qq|<!-- *** STEP 7:  render line graph *** -->
<g transform="translate(80,30)">
<path  class="lineGraph" d="M|;
  for ($index=0; $index<=$#tests; $index++){
if ($tests[$index][1]){
$svg .= ($index*20).qq|,|.((19-($tests[$index][1]))*20).qq| |;
}
}

$svg .=qq|" />|;
 for ($index=0; $index<=$#tests; $index++){
  if ($tests[$index][1]){
$svg .= qq|<circle cx="|.($index*20).qq|" cy="|.((19-($tests[$index][1]))*20).qq|" r="5" stroke="black" fill="none" stroke-width="2" />|;
}
}
$svg .= qq|</g>|;
    }

    $svg .= qq|<!-- ############################  Lipids ######################### -->|;

  if ( grep (/428|250|790\.2|272/, keys %problem)){
    $svg .= qq|
	      <!-- *** Lipids: render background grid *** -->
	      <g transform="translate(80,500)">
              <rect fill="url(#gridPattern)"
		    x="0" y="0" width="400" height="400">
	      </rect>
  <rect x="0" y="0" fill="url(#redOpacity)" width="400" height="270" />
  <rect x="0" y="270" fill="yellow" opacity=".3" width="400" height="30" />
  <rect x="0" y="300" fill="green" opacity=".3" width="400" height="30" />
  <rect x="0" y="330" fill="green" opacity=".7" width="400" height="70" />
	      </g>
				 
	      <!-- *** Lipids: text label (vertical axis) *** -->
              <g transform="translate(30,800)">
	      <text id="verticalLabel" x="20" y="0" 
		    transform="rotate(-90)"
		    fill="black" 
		    font-size="24">
	       LIPIDS
	       </text>
               <text x="490" y="-200" fill="black" font-size="24">
                 Total Cholesterol
               </text>
               <use xlink:href="#lineBox" x="475" y="-210" />
               <text x="490" y="-150" fill="black" font-size="24">
                 Triglycerides
               </text>
               <use xlink:href="#triangleBox" x="475" y="-160" />
               <text x="490" y="-100" fill="black" font-size="24">
                 LDL
               </text>
               <circle cx="475" cy="-110" r="5" stroke="red" fill="red" stroke-width="2" />
               <text x="490" y="-50" fill="black" font-size="24">
                 HDL
               </text>
               <circle cx="475" cy="-60" r="5" stroke="black" fill="none" stroke-width="2" />
	       </g>
						   
	       <!-- *** Lipids: unit label (vertical axis) *** -->|;
for ($index=0; $index<21; $index++){
$svg .= qq|<g transform="translate(50,|.(900-(20*$index)).qq|)">
           <text id="horizontalLabel" x="0" y="0" 
                 fill="blue" fill-opacity="1" 
                 font-size="18">|.($index*20).qq|</text>
           </g>|;
}

$svg .= qq|<!-- *** Lipids: text label (horizontal axis) *** -->
           <g transform="translate(160,1025)">
           <text id="horizontalLabel" x="0" y="0" 
                 fill="black" fill-opacity="1" 
                 font-size="24">
           Date
           </text>
           </g>

           <!-- *** Lipids: unit label (horizontal axis) *** -->
          |;

    $sql = qq!SELECT date_completed, note 
              FROM tests 
	      WHERE patient_id='!.$patient_id.qq!' AND loinc_num="35200-5" ORDER BY date_ordered!;
    $sth = $dbh->prepare($sql);
    $sth->execute;
    $sth->bind_columns(\($date_completed, $note));
    @totalCholesterol=();
    while ($sth->fetch){push (@totalCholesterol, [$date_completed, $note]);}
    for ($index=0; $index<=$#totalCholesterol; $index++){
      if ($totalCholesterol[$index][1]){
	$svg .= qq|<g transform="translate(|.(80+20*$index).qq|,1000)">
	           <text id="horizontalLabel" x="0" y="0"
	                 transform="rotate(-90)"
	                 fill="blue" fill-opacity="1" 
		         font-size="18">$totalCholesterol[$index][0]</text>
                   </g>|;
      }
    }

    ##### Render Graph
    $sql = qq!SELECT date_completed, note 
      FROM tests 
	WHERE patient_id='!.$patient_id.qq!' AND loinc_num="35217-9" ORDER BY date_ordered!;
    $sth = $dbh->prepare($sql);
    $sth->execute;
    $sth->bind_columns(\($date_completed, $note));
    while ($sth->fetch){push (@triglycerides, [$date_completed, $note]);}

    $sql = qq!SELECT date_completed, note 
      FROM tests 
	WHERE patient_id='!.$patient_id.qq!' AND loinc_num="35197-3" ORDER BY date_ordered!;
    $sth = $dbh->prepare($sql);
    $sth->execute;
    $sth->bind_columns(\($date_completed, $note));
    while ($sth->fetch){push (@HDL, [$date_completed, $note]);}

    $sql = qq!SELECT date_completed, note 
      FROM tests 
	WHERE patient_id='!.$patient_id.qq!' AND loinc_num="35198-1" ORDER BY date_ordered!;
    $sth = $dbh->prepare($sql);
    $sth->execute;
    $sth->bind_columns(\($date_completed, $note));
    while ($sth->fetch){
      if ($note=~/[^1-9]+/){push (@LDL, [$date_completed, '']);}
      else {push (@LDL, [$date_completed, $note]);}
    }

    $svg .= qq|<!-- ## Total Cholesterol ## -->|;

    $svg .= qq|<!-- *** STEP 7:  render line graph *** -->
               <g transform="translate(80,900)">
               <path class="lineGraph" d="M|;
    for ($index=0; $index<=$#totalCholesterol; $index++){
      if ($totalCholesterol[$index][1]){
	$svg .= ($index*20).qq|,|.(-($totalCholesterol[$index][1])).qq| |;
      }
    }
    $svg .=qq|" />|;
    for ($index=0; $index<=$#totalCholesterol; $index++){
      if ($totalCholesterol[$index][1]){
	$svg .= qq|<use xlink:href="#lineBox" x="|.($index*20).qq|" y="|.(-($totalCholesterol[$index][1])).qq|" fill-opacity=".5" />|;
  }
  }
  
$svg .= qq|</g>|;


$svg .= qq|<!-- ## Triglycerides ## -->|;

$svg .=qq|<g transform="translate(80,900)">
<path class="lineGraph" d="M|;
  for ($index=0; $index<=$#triglycerides; $index++){
    if ($triglycerides[$index][1]){
      $svg .= ($index*20).qq|,|.(-($triglycerides[$index][1])).qq| |;
    }
  }
$svg .=qq|" />|;
  for ($index=0; $index<=$#triglycerides; $index++){
    if ($triglycerides[$index][1]){
      $svg .= qq|<use xlink:href="#triangleBox" x="|.($index*20).qq|" y="|.(-($triglycerides[$index][1])).qq|" fill-opacity=".5" />|;
    }
  }
$svg .=qq|</g>|;

$svg .= qq|<!-- ## HDL ## -->|;

$svg .= qq|<g transform="translate(80,900)">
<path class="lineGraph" d="M|;
      for ($index=0; $index<=$#HDL; $index++){
	if ($HDL[$index][1]){
	  $svg .= ($index*20).qq|,|.(-($HDL[$index][1])).qq| |;
	}
      }
      $svg .=qq|" />|;
      for ($index=0; $index<=$#HDL; $index++){
	if ($HDL[$index][1]){
	  $svg .= qq|<circle cx="|.($index*20).qq|" cy="|.(-($HDL[$index][1])).qq|" r="5" stroke="black" fill="none" stroke-width="2" fill-opacity=".5" />|;
	}
      }
$svg .= qq|</g>|;

 $svg .= qq|<!-- ## LDL ## -->|;

$svg .= qq|<g transform="translate(80,900)">
<path class="lineGraph" d="M|;
    for ($index=0; $index<=$#LDL; $index++){
      if ($LDL[$index][1]){
$svg .= ($index*20).qq|,|.(-($LDL[$index][1])).qq| |;
      }
    }
    $svg .=qq|" />|;
    for ($index=0; $index<=$#LDL; $index++){
      if ($LDL[$index][1]){
$svg .= qq|<circle cx="|.($index*20).qq|" cy="|.(-($LDL[$index][1])).qq|" r="5" stroke="red" fill="red" stroke-width="2" />|;
      }
    }
  $svg .= qq|</g>|;
  }

  #############################################################################  Blood Pressure

    if ( grep (/401|250|414|428/, keys %problem)){

$svg .= qq|
	       <!-- *** Blood Presure: render background grid *** -->
	       <g transform="translate(80,1080)">
	       <rect class="gridBox" fill="url(#gridPattern)"
	       x="0" y="0" width="400" height="280">
	       </rect>
	       <rect x="0" y="0" fill="url(#redOpacity)" width="400" height="60" />
	       <rect x="0" y="60" fill="red" opacity=".3" width="400" height="40" />
	       <rect x="0" y="100" fill="yellow" opacity=".3" width="400" height="40" />
	       <rect x="0" y="140" fill="green" opacity=".3" width="400" height="140" />

	       </g>
	       
	       <!-- *** Blood Presure: text label (vertical axis) *** -->
	       <g transform="translate(30,1360)">
	       <text id="verticalLabel" x="20" y="0" 
        transform="rotate(-90)"
        fill="black" 
	       font-size="24">
	       Blood Pressure
	       </text>
               <text x="490" y="-200" fill="black" font-size="24">
                 Systolic
               </text>
               <circle cx="475" cy="-210" r="5" stroke="black" fill="black" stroke-width="2" />
               <text x="490" y="-150" fill="black" font-size="24">
                 Diastolic
               </text>
               <circle cx="475" cy="-160" r="5" stroke="black" fill="none" stroke-width="2" />
	       </g>
	       
	       <!-- *** Blood Presure: unit label (vertical axis) *** -->|;
	       for ($index=0; $index<15; $index++){
		 $svg .= qq|<g transform="translate(50,|.(1360-(20*$index)).qq|)">
  <text id="horizontalLabel" x="0" y="0" 
        fill="blue" fill-opacity="1" 
        font-size="18">|.(($index*10)+50).qq|</text>
</g>|;
	       }
	       
	       $svg .= qq|<!-- *** Blood Presure: text label (horizontal axis) *** -->
<g transform="translate(160,1490)">
  <text id="horizontalLabel" x="0" y="0" 
        fill="black" fill-opacity="1" 
        font-size="24">
        Date
  </text>
</g>

<!-- *** Blood Presure: unit label (horizontal axis) *** -->
|;
	       
	       $sql = qq!SELECT date, Blood_pressure 
              FROM pnotes 
	      WHERE pid='!.$patient_id.qq!' ORDER BY date!;
	       $sth = $dbh->prepare($sql);
	       $sth->execute;
	       $sth->bind_columns(\($date, $Blood_pressure));
	       @tests = ();
	       while ($sth->fetch){push (@tests, [$date, $Blood_pressure]);}
	       for ($index=0; $index<=$#tests; $index++){
		 if ($tests[$index][1]){
		   $svg .= qq|<g transform="translate(|.(80+20*$index).qq|,1460)">
                 <text id="horizontalLabel" x="0" y="0"
                       transform="rotate(-90)"
                       fill="blue" fill-opacity="1" 
                       font-size="18">$tests[$index][0]</text>
               </g>|;
		 }
	       }
	       
	       $svg .= qq|<!-- *** Blood Presure: render line graph *** -->
<g transform="translate(80,1100)">
<path  class="lineGraph" d="M|;
	       for ($index=0; $index<=$#tests; $index++){
		 if ($tests[$index][1]){
		   ($systolic, $diastolic)=split(/\//, $tests[$index][1]);
		   $svg .= ($index*20).qq|,|.((180-($systolic))*2).qq| |;
		 }
	       }
	       
	       $svg .=qq|" />|;
 for ($index=0; $index<=$#tests; $index++){
  if ($tests[$index][1]){
		  ($systolic, $diastolic)=split(/\//, $tests[$index][1]);
$svg .= qq|<circle cx="|.($index*20).qq|" cy="|.((180-($systolic))*2).qq|" r="5" stroke="black" fill="black" stroke-width="2" />|;
$svg .= qq|<circle cx="|.($index*20).qq|" cy="|.((180-($diastolic))*2).qq|" r="5" stroke="black" fill="none" stroke-width="2" />|;
}
}
$svg .= qq|
</g>
<g transform="translate(80,1100)">
<path class="lineGraph" d="M|;
	       for ($index=0; $index<=$#tests; $index++){
		 if ($tests[$index][1]){
		   ($systolic, $diastolic)=split(/\//, $tests[$index][1]);
		   $svg .= ($index*20).qq|,|.((180-($diastolic))*2).qq| |;
		 }
	       }
	       
	       $svg .=qq|" />

</g>
|;
	     }
	 
	 
	 $svg .= qq!</svg>!;
	 print OUTFILE $svg;
      }
##### Print Report
if (param('SubmitButton') eq 'Graphs'){
	 $report .= qq!<object  name="owMain" width="700" height="3000" data="http://localhost/temp.svg" type="image/svg+xml"></object>!;
}
      #####  Missed Mammo
      if (param('SubmitButton') eq 'Missed Mammo'){
	$sql = qq!SELECT fname, lname, DOB, MAX(date_ordered), DATEDIFF(CURDATE(), MAX(date_ordered)), date_completed FROM patient_data LEFT JOIN tests ON patient_data.pid=tests.patient_id WHERE sex='F' and DATEDIFF(CURDATE(), DOB)>18250 and loinc_num='24606-6' and date_completed=NULL GROUP BY lname!;
	$sth = $dbh -> prepare($sql);
	$sth -> execute;
	$sth ->bind_columns(\($fname, $lname, $DOB, $date_ordered, $delay, $date_completed));
    $report .= qq!<table>!;
    $report .= qq!<tr><th>First Name</th><th>Last Name</th><th>Date of Birth</th><th>Date Ordered</th><th>Date Completed</th></tr>!;
    while($sth->fetch){
      if ($delay > 365){
	$report .= qq!<tr><td>$fname</td><td>$lname</td><td>$DOB</td><td>$date_ordered</td><td>$date_completed</td></tr>!;
      }
    } 
    $report .= qq!</table>!;
  }

  if (param('SubmitButton') eq 'No Mammo'){
    $sql = qq!SELECT DISTINCT fname, lname, DOB FROM patient_data INNER JOIN tests ON patient_data.pid=tests.patient_id WHERE patient_id NOT IN (SELECT patient_id from tests where loinc_num='24606-6') AND patient_data.sex='F' AND DATEDIFF(CURDATE(), DOB)>18250!;
    $sth = $dbh -> prepare($sql);
    $sth -> execute;
    $sth ->bind_columns(\($fname, $lname, $DOB));
    $report .= qq!<table>!;
    $report .= qq!<tr><th>First Name</th><th>Last Name</th><th>Date of Birth</th></tr>!;
    while($sth->fetch){
	$report .= qq!<tr><td>$fname</td><td>$lname</td><td>$DOB</td></tr>!;
    } 
    $report .= qq!</table>!;
  }

  #####  Missed Colonoscopy
  if (param('SubmitButton') eq 'Missed Colonoscopy'){
    $sql = qq!SELECT fname, lname, DOB, MAX(date_ordered), DATEDIFF(CURDATE(), MAX(date_ordered)), date_completed FROM patient_data LEFT JOIN tests ON patient_data.pid=tests.patient_id WHERE DATEDIFF(CURDATE(), DOB)>18250 and loinc_num='28022-2' and date_completed=NULL GROUP BY lname!;
    $sth = $dbh -> prepare($sql);
    $sth -> execute;
    $sth ->bind_columns(\($fname, $lname, $DOB, $date_ordered, $delay, $date_completed));
    $report .= qq!<table>!;
    $report .= qq!<tr><th>First Name</th><th>Last Name</th><th>Date of Birth</th><th>Date Ordered</th><th>Date Completed</th></tr>!;
    while($sth->fetch){
      if ($delay > 365){
	$report .= qq!<tr><td>$fname</td><td>$lname</td><td>$DOB</td><td>$date_ordered</td><td>$date_completed</td></tr>!;
      }
    } 
    $report .= qq!</table>!;
  }

  if (param('SubmitButton') eq 'No Colonoscopy'){
    $sql = qq!SELECT DISTINCT fname, lname, DOB FROM patient_data INNER JOIN tests ON patient_data.pid=tests.patient_id WHERE patient_id NOT IN (SELECT patient_id from tests where loinc_num='28022-2') AND DATEDIFF(CURDATE(), DOB)>18250!;
    $sth = $dbh -> prepare($sql);
    $sth -> execute;
    $sth ->bind_columns(\($fname, $lname, $DOB));
    $report .= qq!<table>!;
    $report .= qq!<tr><th>First Name</th><th>Last Name</th><th>Date of Birth</th></tr>!;
    while($sth->fetch){
	$report .= qq!<tr><td>$fname</td><td>$lname</td><td>$DOB</td></tr>!;
    } 
    $report .= qq!</table>!;
  }

  ##### Missed HgbA1c
  if (param('SubmitButton') eq 'Missed HgbA1c'){
    $sql = qq!SELECT fname, lname, DOB, MAX(date_ordered), DATEDIFF(CURDATE(), MAX(date_ordered))  FROM patient_data LEFT JOIN tests ON patient_data.pid=tests.patient_id WHERE loinc_num='17855-8' GROUP BY lname!;
    $sth = $dbh -> prepare($sql);
    $sth -> execute;
    $sth ->bind_columns(\($fname, $lname, $DOB, $date_ordered, $delay));
    $report .= qq!<table>!;
    $report .= qq!<tr><th>First Name</th><th>Last Name</th><th>Date of Birth</th><th>Date Ordered</th></tr>!;
    while($sth->fetch){
      if ($delay > 180){
	$report .= qq!<tr><td>$fname</td><td>$lname</td><td>$DOB</td><td>$date_ordered</td></tr>!;
      }
    } 
    $report .= qq!</table>!;
  }

  ##### All Diabetics
  if (param('SubmitButton') eq 'All Diabetics'){
    $sql = qq!SELECT DISTINCT fname, lname, DOB FROM patient_data LEFT JOIN problem_list ON patient_data.pid=problem_list.patient_id WHERE problem_id='17572' ORDER BY lname!;
    $sth = $dbh -> prepare($sql);
    $sth -> execute;
    $sth ->bind_columns(\($fname, $lname, $DOB));
    $report .= qq!<table>!;
    $report .= qq!<tr><th>First Name</th><th>Last Name</th><th>Date of Birth</th></tr>!;
    while($sth->fetch){
      $report .= qq!<tr><td>$fname</td><td>$lname</td><td>$DOB</td></tr>!;
    } 
    $report .= qq!</table>!;
  }

  #####  Diabetes Report
  if (param('SubmitButton') eq 'Diabetes Report'){
    $sql = qq!SELECT COUNT(DISTINCT patient_id)  FROM tests WHERE loinc_num='17855-8'!;
    $sth = $dbh -> prepare($sql);
    $sth -> execute;
    $sth -> bind_columns(\$Denominator);
    $sth->fetch;


    $sql = qq!SELECT COUNT(*) FROM (SELECT patient_id, MAX(date_completed), note FROM tests WHERE loinc_num='17855-8' Group By patient_id) AS diabetic Where note<7 And note<>''!;
    $sth = $dbh -> prepare($sql);
    $sth -> execute;
    $sth->bind_columns(\$lessSeven);
    $sth->fetch;

    $sql = qq!SELECT COUNT(*) FROM (SELECT patient_id, MAX(date_completed), note FROM tests WHERE loinc_num='17855-8' Group By patient_id) AS diabetic Where note>=7 and note<9 And note<>''!;
    $sth = $dbh -> prepare($sql);
    $sth -> execute;
    $sth->bind_columns(\$sevenNine);
    $sth->fetch;

    $sql = qq!SELECT COUNT(*) FROM (SELECT patient_id, MAX(date_completed), note FROM tests WHERE loinc_num='17855-8' Group By patient_id) AS diabetic Where note>=9 and note<11 And note<>''!;
    $sth = $dbh -> prepare($sql);
    $sth -> execute;
    $sth->bind_columns(\$nineEleven);
    $sth->fetch;

    $sql = qq!SELECT COUNT(*) FROM (SELECT patient_id, MAX(date_completed), note FROM tests WHERE loinc_num='17855-8' Group By patient_id) AS diabetic Where note>=11 And note<>''!;
    $sth = $dbh -> prepare($sql);
    $sth -> execute;
    $sth->bind_columns(\$moreEleven);
    $sth->fetch;

    $sql = qq!SELECT COUNT(*) FROM (SELECT patient_id, MAX(date_completed), note FROM tests WHERE patient_id IN (SELECT DISTINCT patient_id FROM problem_list WHERE problem_id='17572') AND loinc_num='35198-1' AND note<>'' GROUP BY patient_id) AS lipids WHERE note<70 AND note<>'not calculated' !;
    $sth = $dbh -> prepare($sql);
    $sth -> execute;
    $sth->bind_columns(\$less70);
    $sth->fetch;

    $sql = qq!SELECT COUNT(*) FROM (SELECT patient_id, MAX(date_completed), note FROM tests WHERE patient_id IN (SELECT DISTINCT patient_id FROM problem_list WHERE problem_id='17572') AND loinc_num='35198-1' AND note<>'' GROUP BY patient_id) AS lipids WHERE note>=70 and note<100 AND note<>'not calculated' !;
    $sth = $dbh -> prepare($sql);
    $sth -> execute;
    $sth->bind_columns(\$SeventyToOneHundred);
    $sth->fetch;

    $sql = qq!SELECT COUNT(*) FROM (SELECT patient_id, MAX(date_completed), note FROM tests WHERE patient_id IN (SELECT DISTINCT patient_id FROM problem_list WHERE problem_id='17572') AND loinc_num='35198-1' AND note<>'' GROUP BY patient_id) AS lipids WHERE note>=100 AND note<130 AND note<>'not calculated' !;
    $sth = $dbh -> prepare($sql);
    $sth -> execute;
    $sth->bind_columns(\$OneHundredToOneThirty);
    $sth->fetch;

    $sql = qq!SELECT COUNT(*) FROM (SELECT patient_id, MAX(date_completed), note FROM tests WHERE patient_id IN (SELECT DISTINCT patient_id FROM problem_list WHERE problem_id='17572') AND loinc_num='35198-1' AND note<>'' GROUP BY patient_id) AS lipids WHERE note>=130 AND note<160 AND note<>'not calculated' !;
    $sth = $dbh -> prepare($sql);
    $sth -> execute;
    $sth->bind_columns(\$OneThirtyToOneSixty);
    $sth->fetch;

    $sql = qq!SELECT COUNT(*) FROM (SELECT patient_id, MAX(date_completed), note FROM tests WHERE patient_id IN (SELECT DISTINCT patient_id FROM problem_list WHERE problem_id='17572') AND loinc_num='35198-1' AND note<>'' GROUP BY patient_id) AS lipids WHERE note>=160 AND note<190 AND note<>'not calculated' !;
    $sth = $dbh -> prepare($sql);
    $sth -> execute;
    $sth->bind_columns(\$OneSixtyToOneNinety);
    $sth->fetch;

    $sql = qq!SELECT COUNT(*) FROM (SELECT patient_id, MAX(date_completed), note FROM tests WHERE patient_id IN (SELECT DISTINCT patient_id FROM problem_list WHERE problem_id='17572') AND loinc_num='35198-1' AND note<>'' GROUP BY patient_id) AS lipids WHERE note>190 AND note<>'not calculated' !;
    $sth = $dbh -> prepare($sql);
    $sth -> execute;
    $sth->bind_columns(\$more190);
    $sth->fetch;

    $sql = qq!SELECT COUNT(*) FROM (SELECT patient_id, MAX(date_completed), note FROM tests WHERE patient_id IN (SELECT DISTINCT patient_id FROM problem_list WHERE problem_id='17572') AND loinc_num='35198-1' AND note<>'' GROUP BY patient_id) AS lipids WHERE note='not calculated' !;
    $sth = $dbh -> prepare($sql);
    $sth -> execute;
    $sth->bind_columns(\$NotCalculated);
    $sth->fetch;

    $sql = qq!SELECT COUNT(*) FROM (SELECT patient_id, MAX(date_completed), note FROM tests WHERE patient_id IN (SELECT DISTINCT patient_id FROM problem_list WHERE problem_id='17572') AND loinc_num='35198-1' GROUP BY patient_id) AS lipids WHERE note='' !;
    $sth = $dbh -> prepare($sql);
    $sth -> execute;
    $sth->bind_columns(\$Missing);
    $sth->fetch;

    use POSIX;
    $report .= qq!<table class="Report"><caption>HgbA1c</caption>
                  <tr><th class="Report"></th>
                      <th class="Report">Less than 7</th>
                      <th class="Report">7 - 9</th>
                      <th class="Report">9 - 11</th>
                      <th class="Report">More than 11</th>
                      <th class="Report">Total</th>
                  </tr>
                  <tr><th class="Report">Number</th>
                      <td class="Report">$lessSeven</td>
                      <td class="Report">$sevenNine</td>
                      <td class="Report">$nineEleven</td>
                      <td class="Report">$moreEleven</td>
                      <td class="Report">$Denominator</td>
                  </tr>
                  <tr><th class="Report">Percent</th>
                      <td class="Report">!.ceil(100*$lessSeven/$Denominator).qq!</td>
                      <td class="Report">!.ceil(100*$sevenNine/$Denominator).qq!</td>
                      <td class="Report">!.ceil(100*$nineEleven/$Denominator).qq!</td>
                      <td class="Report">!.ceil(100*$moreEleven/$Denominator).qq!</td>
                      <td class="Report">100</td>
                  </tr>
               </table>!;
    $report .= qq!<table class="Report"><caption>LDL</caption>
                  <tr><th class="Report"></th>
                      <th class="Report">Less than 70</th>
                      <th class="Report">70 - 100</th>
                      <th class="Report">100 - 130</th>
                      <th class="Report">130 - 160</th>
                      <th class="Report">160 - 190</th>
                      <th class="Report">More than 190</th>
                      <th class="Report">Not Calculated</th>
                      <th class="Report">Missing</th>
                      <th class="Report">Total</th>
                  </tr>
                  <tr><th class="Report">Number</th>
                      <td class="Report">$less70</td>
                      <td class="Report">$SeventyToOneHundred</td>
                      <td class="Report">$OneHundredToOneThirty</td>
                      <td class="Report">$OneThirtyToOneSixty</td>
                      <td class="Report">$OneSixtyToOneNinety</td>
                      <td class="Report">$more190</td>
                      <td class="Report">$NotCalculated</td>
                      <td class="Report">$Missing</td>
                      <td class="Report">$Denominator</td>
                  </tr>
                  <tr><th class="Report">Percent</th>
                      <td class="Report">!.ceil(100*$less70/$Denominator).qq!</td>
                      <td class="Report">!.ceil(100*$SeventyToOneHundred/$Denominator).qq!</td>
                      <td class="Report">!.ceil(100*$OneHundredToOneThirty/$Denominator).qq!</td>
                      <td class="Report">!.ceil(100*$OneThirtyToOneSixty/$Denominator).qq!</td>
                      <td class="Report">!.ceil(100*$OneSixtyToOneNinety/$Denominator).qq!</td>
                      <td class="Report">!.ceil(100*$more190/$Denominator).qq!</td>
                      <td class="Report">!.ceil(100*$NotCalculated/$Denominator).qq!</td>
                      <td class="Report">!.ceil(100*$Missing/$Denominator).qq!</td>
                      <td class="Report">100</td>
                  </tr>
               </table>!;
    no POSIX;
  }

return ($report);
}

###################################################################################
##  Referrals
##  
##  

sub Referrals {
  my ($referral, $sql, $sth, $Find_Referral, $found_referral, $Add_Referral);

  #####  Add Referral
  if (param('specialty')){
    $sql = "INSERT into referral (specialty";
    if (param('fname')){$sql .= ", fname";}
    if (param('lname')){$sql .= ", lname";}
    if (param('practice')){$sql .= ", practice";}
    if (param('address')){$sql .= ", address";}
    if (param('phone')){$sql .= ", phone";}
    if (param('fax')){$sql .= ", fax";}
    if (param('note')){$sql .= ", note";}
    $sql .= ") VALUES ('".param('specialty')."'";
    if (param('fname')){$sql .= ", '".param('fname')."'";}
    if (param('lname')){$sql .= ", '".param('lname')."'";}
    if (param('practice')){$sql .= ", '".param('practice')."'";}
    if (param('address')){$sql .= ", '".param('address')."'";}
    if (param('phone')){$sql .= ", '".param('phone')."'";}
    if (param('fax')){$sql .= ", '".param('fax')."'";}
    if (param('note')){$sql .= ", '".param('note')."'";}
    $sql .= ")";
    $sth = $dbh->prepare($sql);
    $sth -> execute;
  }

  ## Find Referrals
  $Find_Referral = qq!<table><tr><td>!.$cgi->popup_menu(-name=>'find_referral_by_id',
						      -values=>[Drop_Down_Item_List($dbh, 'referral', 'id', '', 'ID')],
						      -default=>'ID'
						     ).qq!</td>!;
  $Find_Referral .= qq!<td>!.$cgi->popup_menu(-name=>'find_referral_by_specialty',
						      -values=>[Drop_Down_Item_List($dbh, 'referral', 'specialty', '', 'Specialty')],
						      -default=>'Specialty'
						     ).qq!</td>!;
  $Find_Referral .= qq!<td>!.$cgi->popup_menu(-name=>'find_referral_by_practice',
						  -values=>[Drop_Down_Item_List($dbh, 'referral', 'practice', '', 'Practice')],
						  -default=>'Practice'
						 ).qq!</td></tr>!;
  $Find_Referral .= qq!<tr><td>!.$cgi->popup_menu(-name=>'find_referral_by_fname',
						  -values=>[Drop_Down_Item_List($dbh, 'referral', 'fname', '', 'First Name')],
						  -default=>'First Name'
						 ).qq!</td>!;
  $Find_Referral .= qq!<td>!.$cgi->popup_menu(-name=>'find_referral_by_lname',
						  -values=>[Drop_Down_Item_List($dbh, 'referral', 'lname', '', 'Last Name')],
						  -default=>'Last Name'
						 ).qq!</td></tr>!;
  $Find_Referral .= qq!<tr><td>!.$cgi->popup_menu(-name=>'find_referral_by_address',
						  -values=>[Drop_Down_Item_List($dbh, 'referral', 'address', '', 'Address')],
						  -default=>'Address'
						 ).qq!</td></tr>!;
  $Find_Referral .= qq!<tr><td>!.$cgi->popup_menu(-name=>'find_referral_by_phone',
						  -values=>[Drop_Down_Item_List($dbh, 'referral', 'phone', '', 'Phone Number')],
						  -default=>'Phone Number'
						 ).qq!</td>!;
  $Find_Referral .= qq!<td>!.$cgi->popup_menu(-name=>'find_referral_by_fax',
						  -values=>[Drop_Down_Item_List($dbh, 'referral', 'fax', '', 'Fax Number')],
						  -default=>'Fax Number'
						 ).qq!</td></tr>!;
  $Find_Referral .= qq!</table>!;

  $found_referral = qq!<table><tr><td>ID</td><td>Specialty</td><td>Practice</td><td>First Name</td><td>Last Name</td><td>Address</td><td>Phone Number</td><td>Fax Number</td><td>Note</td></tr>!;
  if (
      (param('find_referral_by_id') ne 'ID') || 
      (param('find_referral_by_specialty') ne 'Specialty') || 
      (param('find_referral_by_practice') ne 'Practice') || 
      (param('find_referral_by_fname') ne 'First Name') || 
      (param('find_referral_by_lname') ne 'Last Name') || 
      (param('find_referral_by_address') ne 'Address') || 
      (param('find_referral_by_phone') ne 'Phone Number') || 
      (param('find_referral_by_fax') ne 'Fax Number')){
    $found_referral .= Find_Referral();
  }
  $found_referral .= qq!</table>!;

  
  ### Add Referral
  $Add_Referral .= qq!<table><tr><th>Specialty</th><td><input type='text' name='specialty' /></td>
  <th>Practice</th><td><input type='text' name='practice' /></td></tr>
  <tr><th>First Name</th><td><input type='text' name='fname' /></td>
  <th>Last Name</th><td><input type='text' name='lname' /></td></tr>
  <tr><th>Address</th><td><input type='text' name='address' /></td></tr>
  <tr><th>Phone</th><td><input type='text' name='phone'</td>
  <th>Fax Number</th><td><input type='text' name='fax' /></td></tr>
  <tr><th>Note</th><td><input type='text' name='note' /></td></tr></table>!;
  
  ### Referral Page Layout Table
  $referral = qq!<table>
  <tr><td><fieldset><legend>Find Referral</legend>$Find_Referral</fieldset></td></tr>
  <tr><td><fieldset><legend>Referral List</legend>$found_referral</fieldset></td></tr>
  <tr><td><fieldset><legend>Add Referral</legend>$Add_Referral</fieldset></td></tr>
  </table>!;

  return ($referral);
}

###################################################################################
##  Find Referrals
##

sub Find_Referral {
  my $from = shift;
  my ($sql, $sth, $found_referral);
    $sql="SELECT id, specialty, practice, fname, lname, address, phone, fax, note FROM referral WHERE ";
    if (param('find_referral_by_id') ne 'ID') {$sql.="id = '".param('find_referral_by_id')."' AND ";}  
    if (param('find_referral_by_specialty') ne 'Specialty') {$sql.="specialty = '".param('find_referral_by_specialty')."' AND ";}  
    if (param('find_referral_by_practice') ne 'Practice') {$sql.="practice = '".param('find_referral_by_practice')."' AND ";}  
    if (param('find_referral_by_fname') ne 'First Name') {$sql.="fname = '".param('find_referral_by_fname')."' AND ";}  
    if (param('find_referral_by_lname') ne 'Last Name') {$sql.="lname = '".param('find_referral_by_lname')."' AND ";}  
    if (param('find_referral_by_address') ne 'Address') {$sql.="address = '".param('find_referral_by_address')."' AND ";}  
    if (param('find_referral_by_phone') ne 'Phone Number') {$sql.="phone = '".param('find_referral_by_phone')."' AND ";}
    if (param('find_referral_by_fax') ne 'Fax Number') {$sql.="fax = '".param('find_referral_by_fax')."' AND ";}
    $sql =~ s/(.*)AND $/$1/;
    $sth = $dbh->prepare($sql);
    $sth->execute or die("\nError executing SQL statement! $DBI::errstr");
    my ($id, $specialty, $practice, $fname, $lname, $address, $phone, $fax, $note);
    $sth->bind_columns(\($id, $specialty, $practice, $fname, $lname, $address, $phone, $fax, $note));
    while($sth->fetch){
      if ($from eq 'directory'){
	$found_referral .= qq!<input type='submit' name='SubmitButton' value="$id" class="submit">!;
      } else {
	$found_referral .= qq!<tr><td>$id</td><td>$specialty</td><td>$practice</td><td>$fname</td><td>$lname</td><td>$address</td><td>$phone</td><td>$fax</td><td>$note</td></tr>!;
      }
    }
  return $found_referral;
}

###################################################################################
##  Letters
##  
##  

sub Letters {
  my $patient_id = shift;
  my ($letter, $problem, $chronic, $visit_date, $sql, $sth, $c, $title, $fname, $lname, $DOB, $age, $sex, $date);
  if ($patient_id){
    ($title, $fname, $lname, $DOB, $age, $sex) = Get_Patient_Info($patient_id);
    $date = todays_date();
    $date  =~ s/(\d*)-(\d*)-(\d*)(.*)/$2\/$3\/$1/;

    ##### Work Letter
    if (param('SubmitButton') eq 'Work Letter'){
      $sql = qq!SELECT icd_9_cm_concepts.concept from problem_list INNER JOIN icd_9_cm_concepts ON problem_list.problem_id=icd_9_cm_concepts.id WHERE patient_id="$patient_id"!;
      $sth = $dbh-> prepare($sql);
      $sth->execute;
      $sth->bind_columns(\$problem);
      $letter .= qq!<fieldset><legend>Diagnosis</legend><select name='Diagnosis' />!;
      while ($sth->fetch){
	$letter .= qq!<option value="$problem">$problem</option>!;
      }
      $letter .= qq!</select></fieldset>!;
      $letter .= qq!<fieldset><legend>Seen On</legend><select name="Visit Date">!;
      $sql = qq!SELECT date from pnotes WHERE pid="$patient_id"!;
      $sth = $dbh->prepare($sql);
      $sth->execute;
      $sth->bind_columns(\$visit_date);
      while ($sth->fetch){
	$letter .= qq!<option value="$visit_date">$visit_date</option>!;
      }
      $letter .= qq!</select></fieldset>!;
      $letter .= qq!<fieldset><legend>Return Date</legend><input type='text' name='Return Date' id="calendar"/></fieldset>!;
      $letter .= qq!<fieldset><legend>Comment</legend><textarea name='Comment' rows='5' cols='75'></textarea></fieldset>!;
    }

    ##### Lab Notification
    if (param('SubmitButton') eq 'Lab Notification'){
      $letter .= qq!<fieldset><legend>Tests Done</legend><select name='Tests Done'>
<option value='blood work'>blood work</option>
<option value='x-ray'>x-ray</option>
<option value='ultrasound'>ultrasound</option>
<option value='PAP smear'>PAP smear</option>
<option value='mammogram'>mammogram</option>
<option value='CT scan'>CT scan</option>
<option value='MRI'>MRI</option>
<option value='stress test'>stress test</option>
<option value='echocardiogram'>echo</option>
<option value='Holter monitor'>Holter monitor</option>
<option value='Event monitor'>Event monitor</option>
<option value='Bone Densitometry (DEXA)'>Bone Densitometry (DXA) Report</option>
<option value='Urinalysis'>Urine test</option>
<option value='Pulmonary Function Test'>PFT</option>
<option value='Colonoscopy'>Colonoscopy</option>
<option value='Essphagogastroduodenoscopy (EGD)'>EGD</option>
<option value='biopsy'>biopsy</option>
<option value='culture'>culture</option>
<option value='Semen Analysis'>Semen</option>
<option value='Breath Test'>Breath Test</option>
</select>
</fieldset>
<fieldset><legend>Result Interpretation</legend>
<select name='Result Interpretation'>
<option value='normal'>normal</option>
<option value='abnormal'>abnormal</option>
<option value='unchanged'>unchanged</option>
<option value='boderline'>borderline</option>
<option value='improved'>improved</option>
<option value=''></option>
<option value=''></option>
</select><br>
Result Comment <textarea name='Result Comment' rows='5' cols='75'></textarea>
</fieldset>
<fieldset><legend>Recommendations</legend>
<input type='checkbox' name='Continue Current Management'> Continue Current Management<br>
Diet: <select name='Diet' default=''>
<option value=''></option>
<option value='No change in your diet'>No Change</option>
<option value='Follow a low fat diet'>Low Fat</option>
<option value='Avoid simple sugars and sweets in your diet'>Avoid Simple Sugars, Sweets</option>
<option value='Follow a low salt diet'>Low Salt</option>
<option value=''></option>
</select>
Other Diet Advice: <input type='text' name='Other Diet Advice'><br>
<input type='checkbox' name='No Medication Change'> No Medication Change<br>
Consider starting: <input type='text' name='Consider Starting Medication'><br>
Change Dose: <input type='text' name='Change Medication Dose'><br>
Stop Medication: <input type='text' name='Stop Medication'><br>
Other Medication Adivice: <input type='text' name='Other Medication Advice'><br>
  Consultation: <input type='text' name='Consultation'><br>
Follow-up Visit: <select name='follow-up number' default=''><option value=''></option>!;
      for ($c=1; $c<13; $c++){$letter .= qq!<option value="$c">$c</option>!;}
      $letter .= qq!</select><select name='follow-up unit' default=''>
<option value=''></option>
<option value='days'>days</option>
<option value='weeks'>weeks</option>
<option value='months'>months</option>
</select><br>
Other Comments: <textarea name='Other Recommendations' rows='5' cols='75'></textarea>
</fieldset>
<input type='checkbox' name='See Enclosed Results'> See Enclosed Results<br>
!;
    }
    
    ##### Patient Discharge
    if (param('SubmitButton') eq 'Patient Discharge'){
      
    }

    ##### Physician Discharge
    if (param('SubmitButton') eq 'Physician Discharge'){
      
    }
    
    ##### Transfer Records
    if (param('SubmitButton') eq 'Transfer Records'){
      
    }
    
    ##### Blank Letter
    if (param('SubmitButton') eq 'Blank Letter'){
      $letter .= qq!<input type='checkbox' name='ToPatient'>Dear !; 
      if ($title){
	if (($title eq "MD") || ($title eq "PhD")){
	  $letter .= "Dr. ";
	} else {$letter .= qq!$title!;}
	} else {
	  if ($sex eq 'M'){$letter .= qq!Mr. !;}
	  if ($sex eq 'F'){$letter .= qq!Ms. !;}	  
	}
	
      $letter .= qq!$lname <input type='text' name='Salutation'><br> 
<textarea name='Letter Content' rows = '10' cols='75'></textarea>
  !;
      }
      
      if (param('SubmitButton') eq 'Print'){
	$letter .= qq!<div class='Letter'><p>$date</p><br><br>!;
	
	############################## Work Letter
	if (param('Hidden_Letter') eq 'Work Letter'){
	  $letter .= "<p>To whom it may concern:</p><br><p>I am the physician caring for"; 
	  if ($title){
	    if (($title eq "MD") || ($title eq "PhD")){
	      $letter .= "Dr. ";
	    } else {$letter .= qq!$title!;}
	  } else {
	    if ($sex eq 'M'){$letter .= qq!Mr. !;}
	    if ($sex eq 'F'){$letter .= qq!Ms. !;}	  
	  }
	  $letter .= "$fname $lname (DOB: $DOB).  I saw ";
	  if ($sex eq 'M'){$letter .= qq!him !;}
	  if ($sex eq 'F'){$letter .= qq!her !;}
	  $letter .= qq!most recently on !.param('Visit Date').qq!.</p>!;
	  if (param('Return Date')){
	    if ($sex eq 'M'){$letter .= qq!<p>He !;}
	    if ($sex eq 'F'){$letter .= qq!<p>She !;}
	    $letter .= qq!will be able to return to work on !.param('Return Date').qq!.</p>!;
	  }
	  $letter .= qq!<p>Diagnosis: !.param('Diagnosis').qq!</p>!;
	  if (param('Comment')){
	    $letter .= param('Comment');
	  }
	}
	
	if (param('Hidden_Letter') eq 'Lab Notification'){
	  $letter .= qq!<p>Dear !;
	  if ($title){
	    if (($title eq "MD") || ($title eq "PhD")){
	      $letter .= "Dr. ";
	    } else {$letter .= qq!$title!;}
	  } else {
	    if ($sex eq 'M'){$letter .= qq!Mr. !;}
	    if ($sex eq 'F'){$letter .= qq!Ms. !;}	  
	  }
	  $letter .= qq! $lname,</p><br><br>
	    <p>I am writing to inform you of  your recent !.param('Tests Done').qq!. The result was !.param('Result Interpretation').qq!.  !;
	if (param('Result Comment')){
	  $letter .= param('Result Comment').qq!</p>!;
	} else {$letter .= qq!</p>!;}
	#	$chronic = Chronic_Care_Assessment($patient_id);
	#	$chronic =~ s/<\/tr>/<br>/sg;
	#	$chronic =~ s/<[0-9a-zA-Z\/'%=, ]+>//sg;
	#	$chronic =~ s/(\d\d\d\d-\d\d-\d\d)\d\d\d\d-\d\d-\d\d/$1/sg;
	#	$chronic =~ s/, $//sg;
	
	if (param('Continue Current Management')|| param('Diet') || param('Other Diet Advice') || param('No Medication Change') || param('Consider Starting Medication') || param('Change Medication Dose') || param('Stop Medication') || param('Other Medication Advice') || param('Consultation') || param('follow-up number')){
	  $letter .= qq!I would recommend:<br><br>!;
	  if (param('Continue Current Management')){
	    $letter .= qq!<p class='indent'>Continue your current managment</p>!;
	  }
	  if (param('Diet')){
	    $letter .= qq!<p class='indent'>!.param('Diet').qq!</p>!;
	  }
	  if (param('Other Diet Advice')){
	    $letter .= qq!<p class='indent'>!.param('Other Diet Advice').qq!</p>!;
	  }
	  if (param('No Medication Change')){
	    $letter .= qq!<p class='indent'>No changes in your medication</p>!;
	  }
	  if (param('Consider Starting Medication')){
	    $letter .= qq!<p class='indent'>Consider starting !.param('Consider Starting Medication').qq!</p>!;
	  }
	  if (param('Change Medication Dose')){
	    $letter .= qq!<p class='indent'>Change !.param('Change Medication Dose').qq!</p>!;
	  }
	  if (param('Stop Medication')){
	    $letter .= qq!<p class='indent'>Stop taking !.param('Stop Medication').qq!</p>!;
	  }
	  if (param('Other Medication Advice')){
	    $letter .= qq!<p class='indent'>!.param('Other Medication Advice').qq!</p>!;
	  }
	  if (param('Consultation')){
	    $letter .= qq!<p class='indent'>Please consult !.param('Consultation').qq!</p>!;
	  }
	  if (param('follow-up number')){
	    $letter .= qq!<p class='indent'>Please make a follow-up appoint in !.param('follow-up number').qq! !.param('follow-up unit').qq!.  !;
	  }
	}
	if (param('Other Recommendations')){
	  $letter .= param('Other Recommendations');
	}
      }
					    
					    if (param('Hidden_Letter') eq 'Blank Letter'){
					      $letter .= qq!<p>!;
					      if (param('ToPatient')){
						if ($title){$letter .= qq!$title!;}
						else {
						  if ($sex eq 'M'){$letter .= qq!Mr. !;}
						  if ($sex eq 'F'){$letter .= qq!Ms. !;}	  
						}
						$letter .= qq! $lname,</p><br><br>!;
					      }
					      elsif (param('Salutation')){$letter .= param('Salutation').",</p><br><br>"}
					      $letter .= param('Letter Content');
					    }
      
      $letter .= qq!<br><br>Sincerely,<br><br><br><br>Edwin R. Young, M.D.!;
      if (param('See Enclosed Results')){
	$letter .= qq!<br><br>p.s.  Please See Enclosed Results!;
      }
      $letter .= qq!</div>!;
      $date  =~ s/(\d*)\/(\d*)\/(\d*)(.*)/$3-$1-$2/;
      $sql = qq!INSERT into letters (patient_id, provider_id, date, letter) 
VALUES ("$patient_id", "!.param('hidden_provider_id').qq!", "$date", "$letter")!;
		$sth = $dbh->prepare ($sql);
		$sth->execute;
	      }
	  } else {
	    $letter = qq!<h1 class="comp">No patient identification offered</h1><h3>Please go to Main Screen to select a patient<h3>!;
  }

    
  return ($letter);
  
}

#################################################################################################################################
##
##    Print Letter
##


sub Print_Letter {
  my ($patient_id, $date) = @_;
  my ($letter, $problem, $chronic, $visit_date, $sql, $sth, $c);
  my ($title, $fname, $lname, $DOB, $age, $sex) = Get_Patient_Info($patient_id);
  $date  =~ s/(\d*)-(\d*)-(\d*)(.*)/$3-$1-$2/;
  $sql = qq!SELECT letter from letters where patient_id=$patient_id AND date="$date"!;
  $sth = $dbh->prepare($sql);
  $sth->execute;
  $sth->bind_columns(\$letter);
  $sth->fetch;
  return $letter
}


#################################################################################
##  Package Copde Translation
##
##

sub PackageTranslate {
  my $code = shift;
  my $translation;

  if ($code eq "AMP"){$translation = "AMPULE";}  
  if ($code eq "BAG"){$translation = "BAG";}  
  if ($code eq "BLPK"){$translation = "BLISTER PACK";}  
  if ($code eq "BOT"){$translation = "BOTTLE";}  
  if ($code eq "BOTDR"){$translation = "BOTTLE, DROPPER";}  
  if ($code eq "BOTGL"){$translation = "BOTTLE, GLASS";}  
  if ($code eq "BOTHD"){$translation = "BOTTLE, HDPE";}  
  if ($code eq "BOTPL"){$translation = "BOTTLE, PLASTIC";}  
  if ($code eq "BOTPU"){$translation = "BOTTLE, PUMP";}  
  if ($code eq "BOTSPR"){$translation = "BOTTLE, SPRAY";}  
  if ($code eq "BOTUD"){$translation = "BOTTLE, UNIT-DOSE";}  
  if ($code eq "BOTAP"){$translation = "BOTTLE, WITH APPLICATOR";}  
  if ($code eq "BOX"){$translation = "BOX";}  
  if ($code eq "BOXUD"){$translation = "BOX, UNIT-DOSE";}  
  if ($code eq "CAN"){$translation = "CAN";}  
  if ($code eq "CSTR"){$translation = "CANISTER";}  
  if ($code eq "CSTRRE"){$translation = "CANISTER, REFILL";}  
  if ($code eq "CRTN"){$translation = "CARTON";}  
  if ($code eq "CTG"){$translation = "CARTRIDGE";}
  if ($code eq "CASE"){$translation = "CASE";}  
  if ($code eq "CTR"){$translation = "CONTAINER";}  
  if ($code eq "CUP"){$translation = "CUP";}  
  if ($code eq "CUPUD"){$translation = "CUP, UNIT-DOSE";}  
  if ($code eq "CYL"){$translation = "CYLINDER";}  
  if ($code eq "DEW"){$translation = "DEWAR";}  
  if ($code eq "DLPK"){$translation = "DIALPAK";}  
  if ($code eq "DSPK"){$translation = "DOSE PACK";}  
  if ($code eq "DRM"){$translation = "DRUM";}  
  if ($code eq "DRMFI"){$translation = "DRUM, FIBER";}  
  if ($code eq "INHL"){$translation = "INHALER";}  
  if ($code eq "INHLNA"){$translation = "INHALER, NASAL";}  
  if ($code eq "INHLRE"){$translation = "INHALER, REFILL";}  
  if ($code eq "JAR"){$translation = "JAR";}  
  if ($code eq "JUG"){$translation = "JUG";}  
  if ($code eq "KIT"){$translation = "KIT";}  
  if ($code eq "NS"){$translation = "NOT STATED";}  
  if ($code eq "PKG"){$translation = "PACKAGE";}  
  if ($code eq "PKGCOM"){$translation = "PACKAGE, COMBINATION";}
  if ($code eq "PKT"){$translation = "PACKET";}
  if ($code eq "POU"){$translation = "POUCH";}
  if ($code eq "SYR"){$translation = "SYRINGE";}
  if ($code eq "SYRGL"){$translation = "SYRINGE, GLASS";}
  if ($code eq "SYRPL"){$translation = "SYRINGE, PLASTIC";}
  if ($code eq "SYRPRE"){$translation = "SYRINGE, PRE-FILLED";}
  if ($code eq "TANK"){$translation = "TANK";}
  if ($code eq "TRAY"){$translation = "TRAY";}
  if ($code eq "TUB"){$translation = "TUBE";}
  if ($code eq "TUBAP"){$translation = "TUBE, WITH APPLICATOR";}
  if ($code eq "VIL"){$translation = "VIAL";}
  if ($code eq "VILGL"){$translation = "VIAL, GLASS";}
  if ($code eq "VILMD"){$translation = "VIAL, MULTI-DOSE";}
  if ($code eq "VILPAT"){$translation = "VIAL, PATENT DELIVERY SYSTEM";}
  if ($code eq "VILPHAR"){$translation = "VIAL, PHARMACY BULK PACKAGE";}
  if ($code eq "VILPIG"){$translation = "VIAL, PIGGYBACK";}
  if ($code eq "VILPL"){$translation = "VIAL, PLASTIC";}
  if ($code eq "VILSD"){$translation = "VIAL, SINGLE-DOSE";}
  if ($code eq "VILSU"){$translation = "VIAL, SINGLE-USE";}
  if ($code eq "VILSU"){$translation = "VIAL, WITH INJECTION SET";}

  return ($translation);
}

#########################################################################
##  Patient Note
##  Print patient note give patient_id and date
##

sub Patient_Note {
  my ($patient_id, $date)=@_;
  
}

#Storage:  

# use CGI qw(:standard :html3);
# use CGI::CARP qw(fatalsToBrowser);
# use APACHE::DBI;
