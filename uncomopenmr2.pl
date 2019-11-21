#!/usr/bin/perl -w

use strict 'vars';
use warnings;
use DBI;
use CGI qw(:standard :html3);
# use CGI::CARP qw(fatalsToBrowser);
use CGI::Pretty qw( :html3 );
package main;

my $cgi= new CGI;
my %ALL_FIELDS=();
my $dbh='';
my $dbase = 'DBI:mysql:emr';
my %PAGES = (
	     1=>'Login',
	     2=>'Main Screen',
	     3=>'Patient File',
	     4=>'Update Demographics',
	     5=>'Patient Encounters',
	     6=>'New Encounter'
#	     7=>'Patient Transactions',
#	     8=>'Patient File Report',
#	     9=>'Closing Patient File',
#	     10=>'Logout'
	    );

my %patient =('id'=>['ID',20,'','##'],
	      'title'=>['Title',20,'',['--','Mr','Mrs','Ms','MD','PhD','Esq']],
	      'language'=>['Language',20,'',['--','English','Spanish','French','Chinese']],
	      'financial'=>['Financial',20,'','--'],
	      'fname'=>['First Name',20,'','--'],
	      'lname'=>['Last Name',20,'','--'],
	      'mname'=>['Middle Name',20,'','--'],
	      'DOB'=>['Date of Birth',20,'','-YYYY-MM-DD'],
	      'street'=>['Street',20,'','--------'],
	      'postal_code'=>['Postal Code',20,'','#####-####'],
	      'city'=>['City',20,'','--'],
	      'state'=>['State',20,'','--'],
	      'country_code'=>['Country Code',20,'','--'],
	      'ss'=>['Social Security Number',20,'','###-##-####'],
	      'occupation'=>['Occupation',20,'','--'],
	      'phone_home'=>['Home Phone',20,'','###-###-####'],
	      'phone_biz'=>['Buisness Phone',20,'','###-###-####'],
	      'phone_contact'=>['Phone Contact',20,'','###-###-#####'],
	      'phone_cell'=>['Cell Phone',20,'','###-###-####'],
	      'status'=>['Status',20,'','--'],
	      'contact_relationship'=>['Contact Relationship',20,'','--'],
	      'date'=>['Date',20,'','-YYYY-MM-DD'],
	      'sex'=>['Sex',20,'',['M','F']],
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
	      'hipaa_voice'=>['HIPPA Voice',3,'NO',['--','YES','NO']]
	     );

#foreach (values %FIELDS) {
#  grep($ALL_FIELDS{$_}++,@$_);
#}

################################################################################
##  Main Control of flow Section

my ($print_page, $page_name, $found_patient);
if (param) {
  if (param('PageButton')){$page_name = choose_page(param('PageButton'), param('page'));}
  elsif (param('SubmitButton')){$page_name = submit_page(param('SubmitButton'), param('page'));}
}
else {$page_name = 'Login';}

$print_page  = $cgi->header();
$print_page .= $cgi->start_html(-title=>'OpenEMR');
unless(param('SubmitButton') eq "Accept Note"){$print_page .= print_header($page_name);}
$print_page .= start_multipart_form();

if (param){
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
  unless(param('SubmitButton') eq "Accept Note"){$print_page .= Directory();}
  if ($page_name eq "Main Screen") {
    if (param('SubmitButton') eq 'Add Patient Data') {
      add_patient_data();
      $print_page .= Main_Screen();
    }
    elsif (param('SubmitButton') eq 'Find Patient'){
      $print_page .= Main_Screen(find_patient(param('find_patient_by_pid'),
					      param('find_patient_by_lname'),
					      param('find_patient_by_fname'),
					      param('find_patient_by_ss'),
					      param('find_patient_by_DOB')
					     ));
    }
    elsif (param('SubmitButton') =~ /\d+/){
      $print_page .= Patient_File(param('SubmitButton'));
    } 
    else {
      $print_page .= Main_Screen();
    }
  }
  elsif ($page_name eq 'Patient File'){
    $print_page .= Patient_File(param('SubmitButton') || param('patient_id'));
  }
  elsif ($page_name eq 'Update Demographics'){
    $print_page .= Patient_Demographics(param('patient_id'));
  }
  elsif ($page_name eq 'Patient Encounters'){
    if (param('SubmitButton')){
      $print_page .= Patient_Encounters(param('patient_id'), param('SubmitButton'));
    }
    else {
      $print_page .= Patient_Encounters(param('patient_id'), '');
    }
  }
  elsif ($page_name eq 'New Encounter'){
    $print_page .= New_Encounter(param('patient_id'));
  }
  $print_page .= Hidden_Fields($page_name);
  $dbh->disconnect;
}
else {
  $print_page .= print_login();
}

$print_page .= $cgi -> end_form();
$print_page .= $cgi->end_html;
print $print_page;
  
################################################################################
## Given: Direction button and current page, will direct to appropriate action
## and return name of new page
 
sub choose_page {
  my ($PageButton, $page) = @_;
  my %REVERSEPAGES = reverse %PAGES;
  if ($PageButton eq 'Next Page') {$page=$PAGES{$REVERSEPAGES{$page}+1};}
  elsif ($PageButton eq "Previous Page"){$page = $PAGES{$REVERSEPAGES{$page}-1};}
  else {$page = $PageButton;}
  return($page);
}

################################################################################
## Given: Name of submit button and current page.
## Return: Appropriate  name of new page180
 
sub submit_page {
  my ($SubmitButton, $page) = @_;
  if ($page eq 'Login'){$page = 'Main Screen';}
  if ($page eq 'Main Screen'){
    if ($SubmitButton eq 'Add Patient Data'){$page = 'Main Screen';}
    if ($SubmitButton eq 'Find Patient'){$page = 'Main Screen';}
    if ($SubmitButton =~ /\d+/){$page = 'Patient File';}
  }
  if ($page eq 'Patient File'){
    if ($SubmitButton eq 'Update Demographics'){$page = 'Update Demographics';}
    if ($SubmitButton eq 'New Encounter'){$page = 'New Encounter';}
    if ($SubmitButton =~ /^\d/){$page = 'Patient File';}
  }
  if ($page eq 'Patient Encounters'){

  }
  if ($page eq 'New Encounter'){
    if ($SubmitButton eq 'Choose This Problem'){$page = 'New Encounter';}
    if ($SubmitButton eq 'Add Problem'){$page = 'New Encounter';}
    if ($SubmitButton eq 'Search for Problem'){$page = 'New Encounter';}
    if ($SubmitButton eq 'Select Problems'){$page = 'New Encounter';}
    if ($SubmitButton eq 'Change Medication'){$page = 'New Encounter';}
    if ($SubmitButton eq 'Find Medication'){$page = 'New Encounter';}
    if ($SubmitButton eq 'Add Medication'){$page = 'New Encounter';}
    if ($SubmitButton eq 'Discontinue Medication'){$page = 'New Encounter';}
    if ($SubmitButton eq 'Order Test'){$page = 'New Encounter';}
    if ($SubmitButton eq 'Pick Observation Class Type'){$page = 'New Encounter';}
    if ($SubmitButton eq 'Pick Observation Class'){$page = 'New Encounter';}
    if ($SubmitButton eq 'Pick Observation'){$page = 'New Encounter';}
    if ($SubmitButton eq 'Pick Method'){$page = 'New Encounter';}
    if ($SubmitButton eq 'Pick System'){$page = 'New Encounter';}
    if ($SubmitButton eq 'Full Review of Systems'){$page ='New Encounter';}
    if ($SubmitButton eq 'Past/Social/Family History'){$page='New Encounter';}
    if ($SubmitButton eq 'Accept Note'){$page = 'New Encounter';}
  }
  if ($page eq 'New Medication'){

    if ($SubmitButton eq 'Pick Strength'){$page = 'New Medication';} 
  }
  return($page);
}

################################################################################
## Given: name of current page
## Returns: Appropriate header

sub print_header {
  my $page_name= shift;
  my $print_header;

  $print_header .=  table ({-border =>"0", -cellpadding => "0", -cellspacing => "0", -width => "100%"},
			   Tr(td({-width => '33%', -align=>'Left'}, $cgi->h3('UMPA Faculty Practice')),
			      td({-width => '33%', -align=>'Center'}, $cgi->h1($page_name)),
			      td({-width => '33%', -align=>'Center'}, $cgi->h3(scalar localtime(time())))
			     )			  
			  );
  $print_header .= "<BR> \n";
  if ($page_name ne 'Login') {
    $print_header .= "Logged in as ".param('User')."<BR> \n";
  }
  return ($print_header);
}

################################################################################
## Login Screen

sub print_login {
  my $print_login;
  $cgi->delete_all();
  $print_login = $cgi -> table({-border=>'0', -width => "100%"},
			       Tr({-align=>Left,-valign=>TOP},
				  [th('User').td(textfield(-name=>User,-size=>50)), 	
				   th('Password').td(password_field(-name=>Password,-size=>50))]	
				 )	
			      );
  $print_login .= $cgi -> submit(-name=>'PageButton', -value=>'Main Screen');
  $print_login .= Hidden_Fields ('Login');
  return($print_login);
}

################################################################################
## Returns a set of submit buttons to header

sub Directory {
  my $directory = $cgi-> hr();
  foreach my $value(sort values %PAGES){
    $directory .= $cgi->submit(-name=>'PageButton',-value=>$value);
  }
  $directory .= $cgi->submit(-name=>'PageButton',-value=>'Previous Page');
  $directory .= $cgi->submit(-name=>'PageButton',-value=>'Next Page');
  $directory .= $cgi-> hr();
  return ($directory);
}

################################################################################
## 

sub find_patient {
  my ($pid, $lname, $fname, $ss, $dob) = @_;
  my @label=(th('Patient ID').th('Last Name').th('First Name').th('Social Security Number').th('Date of Birth'));
  my (@row, @rows);
  my $main;
  my $sql="SELECT pid,lname,fname,ss,DOB FROM patient_data WHERE ";
  if ($pid ne $patient{'pid'}[3]) {$sql.="pid = '$pid' AND ";}
  if ($lname ne $patient{'lname'}[3]){$sql.="lname = '$lname' AND ";}
  if ($fname ne $patient{'fname'}[3]) {$sql.="fname = '$fname' AND ";}
  if ($ss ne $patient{'ss'}[3]) {$sql.="ss = '$ss' AND ";}
  if ($dob ne $patient{'DOB'}[3]) {$sql.="DOB = '$dob'";}
  $sql =~ s/(.*)AND $/$1/;
  my $sth = $dbh->prepare($sql);
  $sth->execute or die("\nError executing SQL statement! $DBI::errstr");
  my ($pidreturn, $lnamereturn, $fnamereturn, $ssreturn, $dobreturn);
  $sth->bind_columns(\$pidreturn, \$lnamereturn, \$fnamereturn, \$ssreturn, \$dobreturn);
  while($sth->fetch){
    push(@row, (td($cgi->submit(-name=>SubmitButton, -value=>$pidreturn)).td($lnamereturn).td($fnamereturn).td($ssreturn).td($dobreturn)));
  }

  $main .= $cgi->table({-border=>'1', -align=>LEFT, -valign=>TOP},
		       caption("Click on the Patient ID number to select a patient."),
		      $cgi->Tr(@label),
		      $cgi->Tr(\@row)
		     );
  return $main;
}

################################################################################
##

sub add_patient_data {
  my @vals=();
  my @field=();
  @field=('lname','fname','pid','DOB','phone_home');
  foreach (@field) {
    if (param($_)){
    push (@vals, param($_));
    param(-name=>$_, -value=>'');
  }
  }
  chomp (@vals);
  my ($sec,$min,$hour,$mday,$mon,$year,$wday, $yday, $isdst) = localtime;
  $year =~ s/^(\d)/20/;
  $mon = $mon + 1;
  my $sql = "INSERT INTO patient_data (". join(", ", @field). ") VALUES ('". join("', '", @vals). "') ON DUPLICATE KEY UPDATE date='$year-$mon-$mday';";
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
  if ($patient{$field}[3]){
    push (@list,$patient{$field}[3]); # Adds the default value
  }
  else {push (@list, '  ')};
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
  my $page_name   =shift;
  my ($hidden_fields, $sql, $sth, $provider_id, $username, $password);
  if ($page_name eq 'Login'){
  $hidden_fields .= $cgi -> hidden(-name=>'page', -value=>'Login',-override=>1);
  }
  else {
    $sql="SELECT id, username, password from users where username='".param('User')."' AND password='".param('Password')."'";
    $sth=$dbh->prepare($sql);
    $sth->execute;
    $sth -> bind_columns(\($provider_id, $username, $password));
    $sth->fetch;
    $hidden_fields = $cgi->hidden(-name=>'provider_id', -value=>"$provider_id");
    $hidden_fields .= $cgi->hidden(-name=>'page',-value=>$page_name,-override=>1);
    $hidden_fields .= $cgi->hidden(-name=>'User', -value=>$username);
    $hidden_fields .= $cgi->hidden(-name=>'Password', -value=>$password);
    if (param('patient_id')){
      unless (param('SubmitButton') =~/(^[0-9]+$)/){
	$hidden_fields .= $cgi->hidden(-name=>'patient_id', -value=>"$1");
      }
    }
    if (param('SubmitButton') =~ /(^[0-9]+$)/){
      $hidden_fields .= qq!<input type="hidden" name='patient_id' value="$1">!;
    }
    if ($page_name eq 'New Encounter'){
      if (param('Type of Problem') == 3){$hidden_fields .= qq!<input type="hidden" name='Problem Text Search' value='3'>!;}
      if (param('Type of Problem') == 2){$hidden_fields .= qq!<input type="hidden" name='Problem Text Search' value='2'>!;}
      if (param('Type of Problem') == 1){$hidden_fields .= qq!<input type="hidden" name='Problem Text Search' value='1'> !;}
      if (param('Type of Problem') == 0){$hidden_fields .= qq!<input type="hidden" name='Problem Text Search' value='0'> !;}
      if ((param('SubmitButton') eq "New Encounter") || ((param('Pick Problem') eq "Yes") && (param('Todays Problems') eq ''))){$hidden_fields .= qq!<input type="hidden" name="Pick Problem" value="Yes">!;}
    }
  }
  return ($hidden_fields);
}

################################################################################
## 'Main_Screen' page

sub Main_Screen {
  my $found_patient = shift;
  my ($Find_Patient_Data, $Add_Patient_Data, $main);

  ## Find Patient Data
  $Find_Patient_Data .= $cgi->submit(-name=>'SubmitButton', -value=>'Find Patient');
  my @labels = ('pid','lname','fname','ss','DOB');
  my (@label_row,@list_row);
  foreach (@labels){
    push(@label_row,$patient{$_}[0]);
    push(@list_row,$cgi->popup_menu(-name=>'find_patient_by_'.$_,
				    -values=>[Drop_Down_Item_List($dbh, 'patient_data', $_, '')],
				    -default=>$patient{$_}[3]
				   )
	);
  }
  $Find_Patient_Data.=$cgi->table(
				  {-border=>'0'},
				  Tr(th(\@label_row)),
				  Tr(td(\@list_row))
				 );
  
  ### Add Patient Data
  $Add_Patient_Data.=$cgi->submit(-name=>SubmitButton, -value=>'Add Patient Data');
  my (@rows, @list, $list);
  my @keys = ('lname','fname','pid','DOB','phone_home');
  my $point = \%patient;
  foreach (@keys) {
    $list = $$point{$_};
    push (@rows,th($list->[0]).td(textfield(-name=>$_, -size=>$list->[1], -default=>$list->[2])));
  }
  $Add_Patient_Data.=$cgi->table({-border=>'0'},Tr({-align=>LEFT,-valign=>TOP},\@rows));
  
  ### Main Page Layout Table
  $main = $cgi->table({-border=>'', -width=>'100%'},
		      Tr(td($Find_Patient_Data).td({-rowspan => '2'},$found_patient)),
		      Tr(td($Add_Patient_Data))
		     );
  return $main;
}

################################################################################
## 'Patient File' page
 
sub Patient_File {
  my $patient_id;
  if (param('patient_id')){$patient_id = param('patient_id');} else{$patient_id = shift;}
  my ($sql, $ref, $page, $name, $identification, $contact_information, $additional, $extra, $problems, $medications, $prevention, $immunizations, $chroniccare, $counselling, $sexCancer, $concept, $code, $date_added, $active, $chronic);
  my(@meds, @started, @stopped, @modified, @filled, @expires, @row, @chronic, @ongoing, @acute);
  my (%immunization_hash);

  ############################################  Patient Demographics
  $sql = "SELECT  title, language, fname, lname, mname, DOB, street, postal_code, city, state, country_code, ss, occupation, phone_home, phone_biz, phone_contact, phone_cell, status, contact_relationship, date, sex, referrer, provider_id, email, ethnoracial, interpretter, family_size, hipaa_mail, hipaa_voice , allergies, phone_pharmacy, healthcare_proxy
          FROM patient_data 
          WHERE pid = '$patient_id'";
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
    $provider_id = (Drop_Down_Item_List($dbh, 'users', 'lname',"id = '".$provider_id."'"))[0];
    if ($title) {$name = $title." ";} $name = $fname." "; if ($mname){$name .= $mname." ";} $name .= $lname;
    $identification = qq!<table border='0' align=LEFT>
<tr  align=LEFT><th><b>Date of Birth: </b></th><td>$DOB</td></tr>
<tr  align=LEFT><th><b>Primary Physician: </b></th><td>$provider_id</td></tr>
<tr  align=LEFT><th><b>Specialist: </b></th><td></td></tr>
</table>!;
    $contact_information = qq!<table border='0' align=LEFT>
<tr align=LEFT><th><b>Address</b></th><td>$street</td></tr>
<tr align=LEFT><th><b>City</b></th><td>$city</td></tr>
<tr align=LEFT><th><b>State</b></th><td>$state</td></tr>
<tr align=LEFT><th><b>Zip</b></th><td>$postal_code</td></tr>
<tr align=LEFT><th><b>Country</b></th><td>$country_code</td></tr>
<tr align=LEFT><th><b>Home Phone</b></th><td>$phone_home</td></tr>
<tr align=LEFT><th><b>Business Phone</b></th><td>$phone_biz</td></tr>
<tr align=LEFT><th><b>Cell Phone</b></th><td>$phone_cell</td></tr>
<tr align=LEFT><th><b>Phone Conact</b></th><td>$phone_contact</td></tr>
<tr align=LEFT><th><b>e-mail</b></th><td>$email</td></tr>
</table>!;
    $additional = qq!<table border='0' align=LEFT>
<tr align=LEFT><th><b>Occupation</b></th><td>$occupation</td></tr>
<tr align=LEFT><th><b>Language</b></th><td>$language</td></tr>
<tr align=LEFT><th><b>Race/Ethnicity</b></th><td>$ethnoracial</td></tr>
<tr align=LEFT><th><b>Gender</b></th><td>$sex</td></tr>
<tr align=LEFT><th><b>Domestic Partner</b></th><td>$status</td></tr>
<tr align=LEFT><th><b>Social Security Number</b></th><td>$ss</td></tr>
</table>!;
    $extra = qq!<table border='0' align=LEFT>
<tr align=LEFT><th><b>Allergies: </b></th><td>$allergies</td></tr>
<tr align=LEFT><th><b>Pharmacy Phone: </b></th><td>$phone_pharmacy</td></tr>
<tr align=LEFT><th><b>Healthcare Proxy: </b></th><td>$healthcare_proxy</td></tr>
</table>!;
    $page = qq!<table border='0' width='100%'>
</table>!;
  }
  #####################################################################  Problem List
  $problems = qq!<table border='0' width='100%'>
<tr><th width='75%' align='LEFT'>Medical/Surgical Problem List</th>
<th align="LEFT">ICD.9</th>
<th align="LEFT">Date of<BR>Onset</th>
<th align="LEFT">Active</th>
</tr>!;
  $sql   = "SELECT concept, code, date_added, active, chronic 
            FROM problem_list LEFT JOIN icd_9_cm_concepts ON problem_list.problem_id=icd_9_cm_concepts.id 
            WHERE patient_id='".$patient_id."'";
  $sth = $dbh->prepare($sql);
  $sth ->execute;
  $sth ->bind_columns(\($concept, $code, $date_added, $active, $chronic));
  while ($sth->fetch){
    $concept =~s/(.*)\[.*\]/$1/;
    if ($active == 1){$active = "Yes";}else{$active = "No";}
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
  for ($index = 0; $index<=$#chronic; $index++){
    $problems .= qq!<tr><td>$chronic[$index][0]</td><td>$chronic[$index][1]</td><td>$chronic[$index][2]</td><td>$chronic[$index][3]</td></tr>!;
  }
  for ($index = 0; $index<=$#ongoing; $index++){
    $problems .= qq!<tr><td>$ongoing[$index][0]</td><td>$ongoing[$index][1]</td><td>$ongoing[$index][2]</td><td>$ongoing[$index][3]</td></tr>!;
  }
  for ($index = 0; $index<=$#acute; $index++){
    $problems .= qq!<tr><td>$acute[$index][0]</td><td>$acute[$index][1]</td><td>$acute[$index][2]</td><td>$acute[$index][3]</td></tr>!;
  }
  $problems .= "</table>";

  ####################################################################  Medication List

  $medications = qq{<table border='0', -width='100%', -hspace='0'>
<tr align='LEFT'>
<th width='75%'>Medication List</th>
<th align='LEFT'>Date Added</th>
<th align='LEFT'>Date Modified</th>
<th align='LEFT'>Date Stopped</th>
<th align='LEFT'>Last Filled</th>
<th align='LEFT'>Expires</th></tr>
			    };

  $sql = "SELECT drug, dosage, unit, route_name, frequency, date_added, date_modified, date_stopped, date_filled, refills 
          FROM prescriptions LEFT JOIN tblroute ON prescriptions.route=tblroute.route_code 
          WHERE patient_id = '".$patient_id."'";
  $sth = $dbh->prepare($sql);
  $sth->execute or die("\nError executing SQL statement! $DBI::errstr");
  while  ($ref = $sth->fetch){
    @$ref[5]  =~ s/(\d*)-(\d*)-(\d*)(.*)/$2\/$3\/$1/;
    $medications .= qq{<tr><font size="-1">
<td>@$ref[0] @$ref[1] @$ref[2] @$ref[3] @$ref[4]</td>
<td>@$ref[5]</td>
<td>@$ref[6]</td>
<td>@$ref[7]</td>
<td>@$ref[8]</td>
<td>@$ref[9]</td>
</font></tr>};
  }
  $medications .= qq!</table>!;

  ################################################################### Screening Tests

  $prevention = Screening_Prevention($sex, $DOB);

  ################################################################### Immunizations

  $sql = "SELECT immunizations.administered_date, immunization.name 
          FROM immunizations LEFT JOIN immunization ON immunizations.immunization_id=immunization.id 
          WHERE immunizations.patient_id='".$patient_id."' and immunizations.administered_date=(SELECT MAX(administered_date) FROM immunizations)"; 
  $sth = $dbh->prepare($sql);
  $sth ->execute;
  while ($ref = $sth->fetch){
    $immunization_hash{@$ref[1]} = @$ref[0];
  }
  $immunizations =  qq!<table border='0' width='100%' hspace='0'><caption><b>Immunizations</b></caption>
<tr align='LEFT'><th width='75%'>Tetanus-dipheria</th><td>$immunization_hash{'Td'}</td><tr>
<tr align='LEFT'><th width='75%'>Influenza</th><td>$immunization_hash{'Influenza 1'}</td><tr>
<tr align='LEFT'><th width='75%'>Pneumonia</th><td>$immunization_hash{'Pneumococcal Conjugate 1'}</td><tr>
<tr align='LEFT'><th width='75%'>Hepatitis B 1</th><td>$immunization_hash{'Hepatitis B 1'}</td><tr?
<tr align='LEFT'><th width='75%'>Hepatitis B 2</th><td>$immunization_hash{'Hepatitis B 2'}</td><tr>
<tr align='LEFT'><th width='75%'>Hepatitis B 3</th><td>$immunization_hash{'Hepatitis B 3'}</td><tr>
<tr align='LEFT'><th width='75%'>MMR 1</th><td>$immunization_hash{'MMR 1'}</td><tr>
<tr align='LEFT'><th width='75%'>MMR 2</th><td>$immunization_hash{'MMR 2'}</td><tr?
</table>
			       !;

  $counselling =  qq{<table border='0' width='100%' hspace='0'><caption><b>Counselling</b></caption>
<tr align='LEFT'><th width='75%'>Safety/injusry Prevention</th><td>--</td></tr>
<tr align='LEFT'><th width='75%'>STD/HIV Prevention</th><td>--</td></tr>
<tr align='LEFT'><th width='75%'>Pregnancy Prevention</th><td>--</td></tr>
<tr align='LEFT'><th width='75%'>Mental Health</th><td>--</td></tr>
<tr align='LEFT'><th width='75%'>Self-Breast Exam</th><td>--</td></tr>
<tr align='LEFT'><th width='75%'>Nutrition</th><td>--</td></tr>
<tr align='LEFT'><th width='75%'>Exercise</th><td>--</td></tr>
<tr align='LEFT'><th width='75%'>Smoking Cessation</th><td>--</td></tr>
<tr align='LEFT'><th width='75%'>Weight Reduction</th><td>--</td></tr>
<tr align='LEFT'><th width='75%'>Drub Abuse</th><td>--</td></tr>
<tr align='LEFT'><th width='75%'>Pain</th><td>--</td></tr>
</table>
			     };
  $chroniccare =   qq{<table border='0' width='100%' hspace='0'><caption><b>Chronic Care Assessment</b></caption>
<tr align='LEFT'><th width='75%'>HgbA1c</th><td>--</td></tr>
<tr align='LEFT'><th width='75%'>Foot Exam</th><td>--</td></tr>
<tr align='LEFT'><th width='75%'>Eye Exam</th><td>--</td></tr>
<tr align='LEFT'><th width='75%'>Urinary Microalbumin</th><td>--</td></tr>
<tr align='LEFT'><th width='75%'>TSH</th><td>--</td></tr>
<tr align='LEFT'><th width='75%'>Lipids</th><td>--</td></tr>
<tr align='LEFT'><th width='75%'>ASA</th><td>--</td></tr>
<tr align='LEFT'><th width='75%'>ACE-inhibitor</th><td>--</td></tr>
<tr align='LEFT'><th width='75%'>Beta-block</th><td>--</td></tr>
<tr align='LEFT'><th width='75%'>Statin</th><td>--</td></tr>
<tr align='LEFT'><th width='75%'>Spironolactone</th><td>--</td></tr>
</table>
			     };

  ##################################  Get Dates of old notes

  my ($note, $note_date, $encounterdates);
  my @encounters;
  $sql           = "SELECT date 
                       FROM pnotes 
                       WHERE  pid = '".$patient_id."' 
                       ORDER by date DESC;";
  $sth           = $dbh->prepare($sql);
  $sth              ->execute;
  while ($ref       = $sth->fetch){
    $encounterdates = @$ref[0];
    $encounterdates =~ s/(\d+)-(\d+)-(\d+)/$2-$3-$1/;
    push(@encounters, (
		       $cgi->submit(-name=>'SubmitButton', -value=>"$encounterdates"),
		       br
		      )
	);
  }

  #################################  If no specific date is given, select most recent note for display
  if ((@encounters) && (param('SubmitButton')!~/^\d\d-\d\d-\d\d\d\d$/)){
    $sql  = "SELECT MAX(date) FROM pnotes WHERE pid='".param('SubmitButton')."'";
    $sth  = $dbh->prepare($sql);
    $sth  ->execute or die("Error executing SQL statement! $DBI::errstr");
    $ref  = $sth->fetch;
    $note_date = @$ref[0];
    $note_date =~ s/(\d+)-(\d+)-(\d+)/$1-$2-$3/;
    $note = Print_Note($patient_id, $note_date);
  }

  #################################  If a specific date is given, select that note for display
  elsif (param('SubmitButton')=~/(^\d\d-\d\d-\d\d\d\d$)/){
    $note_date =$1;
    $note_date=~ s/(\d+)-(\d+)-(\d+)/$3-$1-$2/;
    $note = Print_Note($patient_id, $note_date);
  }
  else{
    $note = "No Encounters";
  }
  unshift (@encounters, ( 
			 $cgi->submit(-name=>'SubmitButton', -value=>'New Encounter'),
			 br,
			 p(b("Previous Encounters"))
			)
	  );

  $page .= qq{<table border='1' width='100%' align=LEFT>
<tr align=LEFT><td width= '25%'><h1>$name</h1></td>
<td width='25%' valign=TOP rowspan='2'>$contact_information</td>
<td width='25%' valign=TOP rowspan='2'>$additional</td>
<td width='25%' valign=TOP>$extra</td></tr>
<tr align=LEFT><td>$identification</td><td><input type="submit" name="SubmitButton" value="Update Demographics"><BR><BR>Last updated: $date</td></tr>
<tr><td valign=TOP colspan='4'>$problems</td></tr>
<tr><td valign=TOP colspan='4'>$medications</td></tr>
<tr><td width='25%' valign=TOP>$prevention</td>
<td width='25%' valign=TOP>$immunizations</td>
<td width='25%' valign=TOP>$chroniccare</td>
<td width='25%' valign=TOP>$counselling</td></tr>
<tr><td width='10%' valign=TOP>@encounters</td>
<td colspan=3 align=LEFT valign=TOP width='90%'>$note</td></tr>
</table>
		      };
  return ($page);
} 

################################################################################
## 'Patient Demographics' page

sub Patient_Demographics {
  my $patient_id = shift;
  my ($sql, $sth, $ref, $tackon, $main, $pop);

  my ($id, $title, $language, $financial, $fname, $lname, $mname, $DOB, $street, $postal_code, $city, $state, $country_code, $ss, $occupation, $phone_home, $phone_biz, $phone_contact, $phone_cell, $status, $contact_relationship, $date, $sex, $referrer, $referrerID, $provider_id, $email, $ethnoracial, $interpretter, $migrantseasonal, $family_size, $monthly_income, $homeless, $financial_review, $pubpid, $pid, $genericname1, $genericval1, $genericname2, $genericval2, $hipaa_mail, $hipaa_voice);

  my (@HeaderRow, @HeaderRow1, @HeaderRow2, @HeaderRow3, @HeaderRow4, @HeaderRow5, @HeaderRow6, @HeaderRow7, @record,  @record1, @record2, @record3, @record4, @record5, @record6, @record7);

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
	      'hipaa_voice'
	     );
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
    $sql .= " WHERE pid = '$patient_id'";
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
		       \$hipaa_voice
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
		 "$hipaa_voice"
		 );
      foreach (@row){                                                 # run through each of the fields in the patient_data file via bound variables
	$pop = shift(@keys);
	push (@HeaderRow, $patient{$pop}[0]);
	if ($_){                                                      # check the variable bound to the database to see if each field already has a value, in which case use that
	    if ($pop eq 'provider_id'){
		push(@record,$cgi->textfield(-name=>$pop, -value=>Drop_Down_Item_List($dbh, 'users', 'lname',"id = '".$_."'")));
	    }else{push(@record,$cgi->textfield(-name=>$pop, -value=>$_));}
	}elsif ($pop eq ('state')){                                   # use the database to fill the pop-up menu
	    push(@record,$cgi->popup_menu(-name=>$pop,
					  -values=>[Drop_Down_Item_List($dbh, 'pop_places', 'state','')],
					  -default=>$patient{$pop}[3]
					  )
		 );	  
	}elsif(($pop eq 'city') && ($state ne '')){
	    push(@record,$cgi->popup_menu(-name=>$pop,
					-values=>[Drop_Down_Item_List($dbh, 'pop_places', 'feature_name', "state = '".$state."'")],
					-default=>$patient{$pop}[3]
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
	    push(@record, $cgi->textfield(-name=>$pop, -value=>$_ -default=>"###-##-####"));
	}
	elsif($pop eq'phone_home'){
	    push(@record, $cgi->textfield(-name=>$pop, -value=>$_ -default=>"###-###-####"));
	}
	elsif($pop eq 'phone_biz'){
	    push(@record, $cgi->textfield(-name=>$pop, -value=>$_ -default=>"###-###-####"));
	}
	elsif($pop eq 'phone_contact'){
	    push(@record, $cgi->textfield(-name=>$pop, -value=>$_ -default=>"###-###-####"));
	}
	elsif($pop eq 'phone_cell'){
	    push(@record, $cgi->textfield(-name=>$pop, -value=>$_ -default=>"###-###-####"));
	}
	elsif($pop eq 'email'){
	    push(@record, $cgi->textfield(-name=>$pop, -value=>$_ -default=>"----@---.---"));
	}
	else{
	  push(@record, $cgi->popup_menu(-name=>$pop,
					 -values=>$patient{$pop}[3]
					 )
	      );
	}
      }
    }
      @HeaderRow1 = splice(@HeaderRow, 0, 6);
      @HeaderRow2 = splice(@HeaderRow, 0, 6);
      @HeaderRow3 = splice(@HeaderRow, 0, 6);
      @HeaderRow4 = splice(@HeaderRow, 0, 6);
      @HeaderRow5 = splice(@HeaderRow, 0, 6);
      @HeaderRow6 = splice(@HeaderRow, 0, 6);
      @HeaderRow7 = splice(@HeaderRow, 0, 6);
      @record1 = splice(@record, 0, 6);
      @record2 = splice(@record, 0, 6);
      @record3 = splice(@record, 0, 6);
      @record4 = splice(@record, 0, 6);
      @record5 = splice(@record, 0, 6);
      @record6 = splice(@record, 0, 6);
      @record7 = splice(@record, 0, 6);
    
    $main .= br();
    $main .= $cgi->table({-border=>'1', -align=>LEFT, -valign=>TOP},
			 caption(h1($fname," ",$lname)),
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
			 $cgi->Tr(th(\@HeaderRow)),
			 $cgi->Tr(td(\@record))
			);
    $main .= $cgi-> submit(-name=>'SubmitButton', -value=>'Update');
    return ($main);
  }
################################################################################
## Patient Encounters Page

sub Patient_Encounters {

#  return $page;
}  

################################################################################
## New Encounter Page

sub New_Encounter {
  my $patient_id = shift;
  my ($page, $note, $patient_info, $DOB, $sex, $cc, $hpi, $ros, $past_history, $pe, $dr, $decision_making) ;
  my ($sql, $sth, $ref, @ref);
  my ($id, $trade_name, $ingredient_name, $strength, $unit, $route, $frequency, $problem_id, $listing_seq_no, $date, $key, $c);
  my ($new_med, $arrayref, @arrayref);
  my (@list, @values, %distinct, %routes);
  my (@concept, @date_added, @test_ordered);
  my @problem_id;
  $page = "";
  ################################################  Get Basic Patient Information given patient id
  ($patient_info, $DOB, $sex) = Get_Patient_Info($patient_id);
  ################################################  Get List of Todays Problems (Either pick from old problems or add a new problem) given patient id
  if ((param('SubmitButton') eq "New Encounter") || ((param('Pick Problem') eq "Yes") && (param('Todays Problems') eq ''))){
    $page = Get_Todays_Problem_List($patient_id);
  }
  ############################### Print Page if 'Todays Problems' have been entered from the select problems menu
  elsif (param('Todays Problems')){
    $page .= Note_Format($patient_id);
  }
  ###############################################  Assessment and Plan
  else {
    ############################################# Insert Subjective/Objective information obtained in the visit into database
    if (param('SubmitButton') eq "Completed Subjective/Objective Component"){Insert_SO();}

    ############################################### Get Subjective/Objective information from database and format it as a note
    $note = Print_Note($patient_id, todays_date());

    ############################### Insert Meds into database
    my @plan;
    if (param('Medication Frequency') && param('Medication Name')){
      $_ = param('Medication Name');
      if ($_ =~ /(.*)\((.*)\)(.*) (.*), (\d+)\[(\d+)\](\d+)/){
	$trade_name = $1;
	$ingredient_name = $2;
	$strength = $3;
	$unit = $4;
	$route = $5;
	$listing_seq_no = $6;
	$problem_id = $7;
      }
      $frequency = param('Medication Frequency');
      $date  =  todays_date();
      $sql   =  "INSERT INTO prescriptions 
                 (drug, dosage, unit, date_added, route, frequency, listing_seq_no, patient_id, problem_id) 
                 VALUES ('".$trade_name."', '".$strength."', '".$unit."', '".$date."', '".$route."', '".$frequency."', '".$listing_seq_no."', '".$patient_id."', '".$problem_id."')";
      $sth   = $dbh->prepare($sql);
      $sth   -> execute;
      $plan[$problem_id] = qq!Add $trade_name $strength $unit, $frequency\n!;
    }
    ############################### Pick Meds to Discontinue in database
    if (param('SubmitButton') eq 'Discontinue Medication'){
      foreach(param('Medications')){
	$sql = qq!UPDATE prescriptions 
                SET active='0', date_stopped="!.todays_date().qq!" 
                WHERE id="$_"!;
      }
      $sth = $dbh->prepare($sql);
      $sth -> execute;
    }
    ############################### Insert Tests into database
    if (param('Test Ordered')){
      my ($loinc_num, $problem_id, $shortname);
      ($loinc_num, $problem_id, $shortname) = split(/\|/, param('Test Ordered'));
      $sql = qq!INSERT INTO tests
                (patient_id, loinc_num, date_ordered, provider_id, problem_id) 
                VALUES ("$patient_id", "$loinc_num", "!.todays_date().qq!", "!.param('provider_id').qq!", "$problem_id")!;
      $sth = $dbh -> prepare($sql);
      $sth ->execute;
      $plan[$problem_id] .= qq!Order $shortname\n!;
    }
    ############################### Print Note and medical decision making
    my $Chief_complaint;
    my @new_med;
    $sql = qq!SELECT Chief_complaint
                FROM pnotes
                WHERE pid="$patient_id" and date='!.todays_date().qq!'!;
    $sth = $dbh -> prepare($sql);
    $sth ->execute;
    $sth ->bind_columns(\$Chief_complaint);
    $sth ->fetch;
    @problem_id = split(/ /, $Chief_complaint);
    unless((param("SubmitButton") eq "Accept Note") || (param("SubmitButton") eq "New Encounter")){
      $page .= qq!<table width="100%" bgcolor="grey">
<tr><td>$note</td></tr>
<tr><td><h3>Medical Decision Making</h3></td></tr>!;
      $sql = qq!SELECT prescriptions.id, drug, dosage, unit, route_name, frequency , problem_id
                FROM prescriptions LEFT JOIN tblroute ON tblroute.route_code=prescriptions.route 
                WHERE patient_id="$patient_id"!;
      $sth = $dbh->prepare($sql);
      $sth ->execute;
      $sth->bind_columns(\($id, $trade_name, $strength, $unit, $route, $frequency, $problem_id));
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
	  $page .= qq!<option value="$trade_name $strength $unit $route $frequency $problem_id">$trade_name $strength $unit $route $frequency</option>!;
	}
	$page .= qq!</select></td></tr>
<tr><td><input type="submit" name="SubmitButton" value="Change Medication"><input type="submit" name="SubmitButton" value="Discontinue Medication"></td></tr>!;
      }
      #########################################################################  Assessment/Plan for each problem
      foreach (@problem_id){
	$sql   = qq!SELECT icd_9_cm_concepts.concept
                    FROM problem_list LEFT JOIN icd_9_cm_concepts ON problem_list.problem_id=icd_9_cm_concepts.id 
                    WHERE problem_list.patient_id="$patient_id" and problem_list.problem_id="$_"! ;
	$sth = $dbh->prepare($sql);
	$sth ->execute;
	$sth ->bind_columns(\($concept[$_]));
	$sth ->fetch;
	#################################################################  Assessment
	$page .= qq!<tr><td><b>$concept[$_]</b></td></tr>
<tr><td>Assessment</td></tr>
<tr><td colspan=4><textarea name="Assessment $_"  rows="5"  cols="100">!;
	if (param("Assessment $_")){$page .= param("Assessment $_");}
	#################################################################  Plan
	$page .= qq!</textarea></td></tr>
<tr><td>Plan</td></tr>
<tr><td colspan=4><textarea name="Plan $_"  rows="5"  cols="100">!;
	if (param("Plan $_") || $plan[$_]){$page .= param("Plan $_").$plan[$_];}
	#################################  New Meds
	$page .= qq!</textarea></td></tr>
<tr valign=TOP><td><input type="submit" name="SubmitButton" value="Find Medication"></td><td>!;
	if (param("Trade Name Search $_")){
	  my $trade_name_search = param("Trade Name Search $_"); $trade_name_search =~s/(\w+).*/$1/;
	  $new_med[$_] = Trade_Name_Search($trade_name_search, $_);}
	elsif (param("Ingredient Name Search $_")){
	  my $ingredient_name_search = param("Ingredient Name Search $_"); $ingredient_name_search =~s/(\w+).*/$1/;
	  $new_med[$_] = Ingredient_Name_Search($ingredient_name_search, $_);}
	else {
	  $new_med[$_] = qq!<table>
<tr><td>Trade Name</td><td><input type=text name="Trade Name Search $_" size='20' /></td></tr>
<tr><td>Ingredient Name</td><td><input type=text name="Ingredient Name Search $_" size='20' /></td></tr>
</table>!;
	}
	$page .= qq!$new_med[$_]</td></tr>!;
	###############################  Order Tests
	if ((param('SubmitButton') eq "Order Test")
         || (param('SubmitButton') eq "Pick Observation Class Type")
         || (param('SubmitButton') eq "Pick Observation Class")
         || (param('SubmitButton') eq "Pick Method")
         || (param('SubmitButton') eq "Pick System")){
	  my ($testClass, $testMethod, $testSystem);
	  if (param("classtype")){
	    $test_ordered[$_] = Test_Search(param("classtype"), $_);
	  }
	  elsif (param("Test Class")) {
	    $test_ordered[$_] = Test_Search(param("Test Class"), $_);
	  }
	  elsif (param("Test Method")){
	    ($testClass, $testMethod) = split(/ /, param("Test Method"));
	    $test_ordered[$_] = Test_Search($testClass, $_, $testMethod);
	  }
	  elsif (param("Test System")){
	    ($testClass, $testMethod, $testSystem) = split(/ /, param("Test System"));
	    $test_ordered[$_] = Test_Search($testClass, $_, $testMethod, $testSystem);
	  }
	}
	else {
	  $test_ordered[$_] = qq!<tr><td><input type="submit" name="SubmitButton" value="Pick Observation Class Type"</td>
<td>Class Type</td><td><select name="classtype">
<option value="1">Laboratory Class</option>
<option value="2">Clinical Class</option>
<option value="3">Claims Attachment</option>
<option value="4">Surveys</option></td></tr>!;
	}
	$page .= qq!$test_ordered[$_]!;
      }
      ########################################################################### Health Maintenance/Prevention
      $page .=qq!<tr><td>Health Maintenance</td></tr>
<tr><td colspan=4><textarea name="Health Maintenance Assessment" rows=5 cols=100>!;
      $decision_making= Screening_Prevention($sex, $DOB);
      $decision_making =~ s/<\/tr>/\n/sg;
      chop $decision_making;
      $decision_making =~ s/<[0-9a-zA-Z\/'%=, ]*>//sg;
      $page .= $decision_making;
      $page .= qq!</textarea></td></tr>
<tr><td colspan=4><textarea name="Health Maintenance Plan" rows=5 cols=100>!;
      if (param('Health Maintenance Plan')){$page .= param('Health Maintenance Plan');}
      $page .= qq!</textarea></td></tr>
<tr><td>Additional Note</td></tr>
<tr><td colspan=4><textarea name='Additional Note' rows=5 cols=100></textarea</td></tr>!;
      ########################################################################### Accept Note
      $page .= qq!<tr><td><input type="submit" name="SubmitButton" value="Accept Note"></td></tr></table>!;
    }
    elsif (param("SubmitButton") eq "Accept Note"){
      my $sql2 = qq!UPDATE pnotes
                SET assessment_plan='!;
      foreach (@problem_id){
	$sql   = qq!SELECT icd_9_cm_concepts.concept
                    FROM problem_list LEFT JOIN icd_9_cm_concepts ON problem_list.problem_id=icd_9_cm_concepts.id 
                    WHERE problem_list.patient_id="$patient_id" and problem_list.problem_id="$_"! ;
	$sth = $dbh->prepare($sql);
	$sth ->execute;
	$sth ->bind_columns(\($concept[$_]));
	$sth ->fetch;
	$sql2 .= qq!$concept[$_]:\nAssessment - !.param("Assessment $_").qq!;\nPlan - !.param("Plan $_").qq!.  \n!;
      }
      if (param('Health Maintenance Assessment')){
	$sql2 .= qq!Health Maintenance:\nAssessment - !.param('Health Maintenance Assessment').qq!;\nPlan - !.param('Health Maintenance Plan').qq!.  \n!;
      }
      if (param('Additional Note')){
	$sql2 .= qq!Additional Note:\n!.param('Additional Note').qq!.  \n!;
      }
      substr($sql2, -3) = qq!' WHERE pid="$patient_id" and date="!.todays_date().qq!"!;
      $sth = $dbh->prepare($sql2);
      $sth ->execute;
      $note = Print_Note($patient_id, todays_date());
      $page .= qq!<table width="100%">
<tr><td>$note</td></tr>
<tr><td>Edwin R. Young, M.D.</td></tr></table>!;
    }
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

sub Print_Note {
  my $patient_id = shift;
  my $note_date = shift;
  $note_date =~s/(\d+)-(\d+)-(\d+).*/$1-$2-$3/;
  my ($sql, $sth, $note);
  my ($title, $fname, $lname, $DOB, $sex);
  $sql = "SELECT title, fname, lname, DOB, sex 
          FROM patient_data 
          WHERE pid='".$patient_id."'";
  $sth = $dbh->prepare($sql);
  $sth ->execute;
  $sth ->bind_columns(\($title, $fname, $lname, $DOB, $sex));
  $sth ->fetch;
  my ($assessment_plan, $Chief_complaint, $concerns, $Location, $Quality, $Quantity, $Timing, $Setting, $Aggrevating_relieving, $Associated_manifestations, $Patient_reaction, $Pain, $General, $Skin, $Head, $Eyes, $Ears, $Nose_sinuses, $Mouth_throat, $Neck, $Breasts, $Respiratory, $Cardiac, $Gi, $Gu, $Male, $Female, $Vascular, $Neurological, $Musc, $Endo, $Heme, $Psych, $Other_symptoms, $Nutritional, $Psych_needs, $Educational_needs, $Blood_pressure, $Heart_rate, $Resp_rate, $Temp, $Blood_glucose, $Height, $Weight, $General_exam, $Skin_exam, $Eye_exam, $Ear_exam, $Nose_exam, $Mouth_exam, $Neck_exam, $Thyroid_exam, $Lymph_exam, $Chest_exam, $Lung_exam, $Heart_exam, $Breast_exam, $Abdomen_exam, $Rectal_exam, $Prostate_exam, $Testespenis_exam, $External_female_exam, $Speculum_exam, $Internal_exam, $Extremities_exam, $Pulses_exam, $Neurologic_exam);
  my (@problem_id, @date_added, @concept);
  $sql = qq!SELECT assessment_plan, Chief_complaint, concerns,  Location, Quality, Quantity, Timing, Setting, Aggrevating_relieving, Associated_manifestations, Patient_reaction, Pain, General, Skin, Head, Eyes, Ears, Nose_sinuses, Mouth_throat, Neck, Breasts, Respiratory, Cardiac, Gi, Gu, Male, Female, Vascular, Neurological, Musc, Endo, Heme, Psych, Other_symptoms, Nutritional, Psych_needs, Educational_needs, Blood_pressure, Heart_rate, Resp_rate, Temp, Blood_glucose, Height, Weight, General_exam, Skin_exam, Eye_exam, Ear_exam, Nose_exam, Mouth_exam, Neck_exam, Thyroid_exam, Lymph_exam, Chest_exam, Lung_exam, Heart_exam, Breast_exam, Abdomen_exam, Rectal_exam, Prostate_exam, Testespenis_exam, External_female_exam, Speculum_exam, Internal_exam, Extremities_exam, Pulses_exam, Neurologic_exam
              FROM pnotes
              WHERE pid='!.$patient_id.qq!' and date='!.$note_date.qq!'!;
  $sth = $dbh->prepare($sql);
  $sth ->execute;
  $sth ->bind_columns(\$assessment_plan, \$Chief_complaint, \$concerns, \$Location, \$Quality, \$Quantity, \$Timing, \$Setting, \$Aggrevating_relieving, \$Associated_manifestations, \$Patient_reaction, \$Pain, \$General, \$Skin, \$Head, \$Eyes, \$Ears, \$Nose_sinuses, \$Mouth_throat, \$Neck, \$Breasts, \$Respiratory, \$Cardiac, \$Gi, \$Gu, \$Male, \$Female, \$Vascular, \$Neurological, \$Musc, \$Endo, \$Heme, \$Psych, \$Other_symptoms, \$Nutritional, \$Psych_needs, \$Educational_needs, \$Blood_pressure, \$Heart_rate, \$Resp_rate, \$Temp, \$Blood_glucose, \$Height, \$Weight, \$General_exam, \$Skin_exam, \$Eye_exam, \$Ear_exam, \$Nose_exam, \$Mouth_exam, \$Neck_exam, \$Thyroid_exam, \$Lymph_exam, \$Chest_exam, \$Lung_exam, \$Heart_exam, \$Breast_exam, \$Abdomen_exam, \$Rectal_exam, \$Prostate_exam, \$Testespenis_exam, \$External_female_exam, \$Speculum_exam, \$Internal_exam, \$Extremities_exam, \$Pulses_exam, \$Neurologic_exam);
  $sth->fetch;
  $DOB =~  s/(\d*)-(\d*)-(\d*)/$2\/$3\/$1/;
  $note_date =~  s/(\d*)-(\d*)-(\d*)/$2\/$3\/$1/;
  $note = qq!<table><tr><th align=LEFT>Progress Note</th><th align=LEFT colspan=7>Date: $note_date</th></tr>
<tr><th align=LEFT>$title $fname $lname</th><th align=LEFT colspan=7> DOB:  $DOB</th></tr><tr><th align=LEFT><h3>Chief Complaint<h3></th><td colspan=7></td></tr>!;
  @problem_id=split(/ /,$Chief_complaint);
  foreach (@problem_id){
    $sql   = qq!SELECT icd_9_cm_concepts.concept, date_added 
                  FROM problem_list LEFT JOIN icd_9_cm_concepts ON problem_list.problem_id=icd_9_cm_concepts.id 
                  WHERE problem_list.patient_id="!.$patient_id.qq!" and problem_list.problem_id="$_"!;
    $sth = $dbh->prepare($sql);
    $sth ->execute;
    $sth ->bind_columns(\($concept[$_], $date_added[$_]));
    while ($sth->fetch){
      $concept[$_] =~ s/(^.*\[.*\]).*/$1/;
      $date_added[$_]=~ s/(\d+)-(\d+)-(\d+)/$2\/$3\/$1/;
      $note .= qq!<tr><td colspan=3>$concept[$_] First Noted: $date_added[$_]</td><td colspan=5></td></tr>!;
    }
  }
  $note .= qq!<tr><td colspan=8><table><tr><th align=LEFT><h3>HPI<h3></th><td colspan=7></td></tr>!;
  foreach (@problem_id){
    $note .= qq!<tr><th align=LEFT colspan=3><b>$concept[$_]</b></th><td colspan=5></td></tr>!;
    if ($concept[$_] =~/\[V/){$note .= qq!<tr><td colspan=1></td><td><b>Concerns: </b>$concerns</td></tr>!;}
    else{
      if($Location){$note .= qq!<tr><td colspan=1></td><td><b>Location: </b>$Location</td></tr>!;}
      if($Quality){$note .= qq!<tr><td colspan=1></td><td><b>Quality: </b>$Quality</td></tr>!;}
      if($Quantity){$note .= qq!<tr><td colspan=1></td><td><b>Quantity: </b>$Quantity</td></tr>!;}
      if($Timing){$note .= qq!<tr><td colspan=1></td><td><b>Timing: </b>$Timing</td></tr>!;}
      if($Setting){$note .= qq!<tr><td colspan=1></td><td><b>Setting: </b>$Setting</td></tr>!;}
      if($Aggrevating_relieving){$note .= qq!<tr><td colspan=1></td><td><b>Aggrevating Relieving: </b>$Aggrevating_relieving</td></tr>!;}
      if($Associated_manifestations){$note .= qq!<tr><td colspan=1></td><td><b>Associated Manifestations: </b>$Associated_manifestations</td></tr>!;}
      if($Patient_reaction){$note .= qq!<tr><td colspan=1></td><td><b>Patient Reaction: </b>$Patient_reaction</td></tr>!;}
    }
  }
  $note .= qq!</table></td></tr><tr><td colspan=8><table>!;
  ############################### Review of Systems 
  $note .= qq!<tr><th align=LEFT><h3>Review of Systems: </h3></td></tr>!;
  if ($Pain ne ""){$note .= qq!<tr><td>Pain: $title $fname $lname has $Pain;  !;}
  if ($General){$note .= qq!General Systems:$General;  !;}
  if ($Skin){$note .= qq!Skin: $Skin;  !;}
  if ($Head){$note .= qq!Head:$Head;  !;}
  if ($Eyes){$note .= qq!Eyes:$Eyes;  !;}
  if ($Ears){$note .= qq!Ears:$Ears;  !;}
  if ($Nose_sinuses){$note .= qq!Nose and Sinuses:$Nose_sinuses;  !;}
  if ($Mouth_throat){$note .= qq!Mouth and Throat:$Mouth_throat;  !;}
  if ($Neck){$note .= qq!Neck:$Neck;  !;}
  if ($Breasts){$note .= qq!Breasts:$Breasts;  !;}
  if ($Respiratory){$note .= qq!Respiratory:$Respiratory;  !;}
  if ($Cardiac){$note .= qq!Cardiac:$Cardiac;  !;}
  if ($Gi){$note .= qq!Gastrointestinal:$Gi;  !;}
  if ($Gu){$note .= qq!Urologic:$Gu;  !;}
  if ($Male){$note .= qq!Male Genital:$Male;  !;}
  if ($Female){$note .= qq!Female Genital:$Female;  !;}
  if ($Vascular){$note .= qq!Peripheral Vascular:$Vascular;  !;}
  if ($Neurological){$note .= qq!Neurological:$Neurological;  !;}
  if ($Musc){$note .= qq!Musculo-Skelatal:$Musc;  !;}
  if ($Endo){$note .= qq!Endocrine:$Endo;  !;}
  if ($Heme){$note .= qq!Hematologic:$Heme;  !;}
  if ($Psych){$note .= qq!Psychiatric:$Psych;  !;}
  if ($Other_symptoms){$note .= qq!Other Symptoms:$Other_symptoms;  !;}
  if ($Nutritional){$note .= qq!Nutritional Needs:$Nutritional;  !;}
  if ($Psych_needs){$note .= qq!Psychological Needs:$Psych_needs;  !;}
  if ($Educational_needs){$note .= qq!Educational Needs:$Educational_needs.</td>!;}
  $note .= qq!</table></td></tr><tr><td colspan=8><table>!;
  
  ############################################## Past Problems
  my ($concept, $code, $date_added, $active, $chronic, @past);
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
  }
  if (@past){$note .= qq!<tr><td>Past Medical History: !;foreach(@past){$note .= qq!$_</td></tr>!;}}
  ############################################## Medical History
  my ($coffee, $alcohol, $drug_use, $sleep_patterns, $exercise_patterns, $std, $reproduction, $sexual_function, $self_breast_exam, $self_testicle_exam, $seatbelt_use, $counseling, $hazardous_activities, $last_social_history,$last_breast_exam, $last_mammogram, $last_gynocological_exam, $last_psa, $last_prostate_exam, $last_physical_exam, $last_sigmoidoscopy_colonoscopy, $last_fecal_occult_blood, $last_ppd, $last_bone_density, $history_mother, $history_father, $history_siblings, $history_offspring, $history_spouse, $relatives_cancer, $relatives_tuberculosis, $relatives_diabetes, $relatives_hypertension, $relatives_heart_problems, $relatives_stroke, $relatives_epilepsy, $relatives_mental_illness, $relatives_suicide, $date, $pid, $name_1, $value_1, $name_2, $value_2, $additional_history);
  $sql = qq!SELECT coffee, alcohol, drug_use, sleep_patterns, exercise_patterns, std, reproduction, sexual_function, self_breast_exam, self_testicle_exam, seatbelt_use, counseling, hazardous_activities, last_social_history, last_breast_exam, last_mammogram, last_gynocological_exam, last_psa, last_prostate_exam, last_physical_exam, last_sigmoidoscopy_colonoscopy, last_fecal_occult_blood, last_ppd, last_bone_density, history_mother, history_father, history_siblings, history_offspring, history_spouse, relatives_cancer, relatives_tuberculosis, relatives_diabetes, relatives_hypertension, relatives_heart_problems, relatives_stroke, relatives_epilepsy, relatives_mental_illness, relatives_suicide, date, pid, name_1, value_1, name_2, value_2, additional_history 
              FROM history_data
              WHERE pid="$patient_id"!;
  $sth = $dbh->prepare($sql);
  $sth ->execute;
  $sth ->bind_columns(\($coffee, $alcohol, $drug_use, $sleep_patterns, $exercise_patterns, $std, $reproduction, $sexual_function, $self_breast_exam, $self_testicle_exam, $seatbelt_use, $counseling, $hazardous_activities, $last_social_history, $last_breast_exam, $last_mammogram, $last_gynocological_exam, $last_psa, $last_prostate_exam, $last_physical_exam, $last_sigmoidoscopy_colonoscopy, $last_fecal_occult_blood, $last_ppd, $last_bone_density, $history_mother, $history_father, $history_siblings, $history_offspring, $history_spouse, $relatives_cancer, $relatives_tuberculosis, $relatives_diabetes, $relatives_hypertension, $relatives_heart_problems, $relatives_stroke, $relatives_epilepsy, $relatives_mental_illness, $relatives_suicide, $date, $pid, $name_1, $value_1, $name_2, $value_2, $additional_history));
  if ($coffee || $alcohol || $drug_use || $sleep_patterns || $exercise_patterns || $std || $reproduction || $sexual_function || $self_breast_exam || $self_testicle_exam || $seatbelt_use || $counseling || $hazardous_activities){
    $note .= qq!<tr><th align=LEFT><h3>Past Social History:</h3></th></tr><tr><td>!;
    if ($coffee){$note .= qq!Coffee: $coffee;  !;}
    if ($alcohol){$note .= qq!Alcohol: $alcohol;  !;}
    if ($drug_use){$note .= qq!Drug Use: $drug_use;  !;}
    if ($sleep_patterns){$note .= qq!Sleep Patterns: $sleep_patterns;  !;}
    if ($exercise_patterns){$note .= qq!Exercise Patterns: $exercise_patterns;  !;}
    if ($std){$note .= qq!Sexually Transmitted Disease: $std;  !;}
    if ($reproduction){$note .= qq!reproduction: $reproduction;  !;}
    if ($sexual_function){$note .= qq!Sexual Function: $sexual_function;  !;}
    if ($self_breast_exam){$note .= qq!Self Breast Exam: $self_breast_exam;  !;}
    if ($self_testicle_exam){$note .= qq!Self Testicle Exam: $self_testicle_exam;  !;}
    if ($seatbelt_use){$note .= qq!Seatbelt Use: $seatbelt_use;  !;}
    if ($counseling){$note .= qq!Counseling: $counseling;  !;}
    if ($hazardous_activities){$note .= qq!Hasardous Activities: $hazardous_activities;  !;}
  }
  $note =~ s/;  $/./;
  $note .= qq!</td></tr></table></td></tr><tr><td colspan=8><table>!;
  
  ################################################ Family History
  if ($history_mother || $history_father || $history_siblings || $history_offspring || $history_spouse || $relatives_cancer || $relatives_tuberculosis || $relatives_diabetes || $relatives_hypertension || $relatives_heart_problems || $relatives_stroke || $relatives_epilepsy || $relatives_mental_illness || $relatives_suicide){
    $note .= qq!<tr><td><h3>Family History:</h3></td></tr>!;
    if ($history_mother){$note .= qq!<tr><td>Mothers History: $history_mother;  !;}
    if ($history_father){$note .= qq!Fathers History: $history_father;  !;}
    if ($history_siblings){$note .= qq!Siblings History: $history_siblings;  !;}
    if ($history_offspring){$note .= qq!Childrens History: $history_offspring;  !;}
    if ($history_spouse){$note .= qq!Spouses History: $history_spouse;  !;}
    if ($relatives_cancer){$note .= qq!Relatives with cancer: $relatives_cancer;  !;}
    if ($relatives_tuberculosis){$note .= qq!Relatives with tuberculosis: $relatives_tuberculosis;  !;}
    if ($relatives_diabetes){$note .= qq!Relative with Diabetes: $relatives_diabetes;  !;}
    if ($relatives_hypertension){$note .= qq!Relative with Hypertension: $relatives_hypertension;  !;}
    if ($relatives_heart_problems){$note .= qq!Relatives with heart problems: $relatives_heart_problems;  !;}
    if ($relatives_stroke){$note .= qq!relatives with stroke: $relatives_stroke;  !;}
    if ($relatives_epilepsy){$note .= qq!Relatives with epilepsy: $relatives_epilepsy;  !;}
    if ($relatives_mental_illness){$note .= qq!Relatives with mental illness: $relatives_mental_illness;  !;}
    if ($relatives_suicide){$note .= qq!Relatives with a history of suicide: $relatives_suicide</td></tr>!;}
  }
  $note =~ s/;  $/./;
  $note .= qq!</table></td></tr><tr><td colspan=8><table>!;
  
  ################################################## Physical Exam
  $note .= qq!<tr><th align=LEFT><h3>Physical Exam:</h3></th></tr>!;
  if ($Blood_pressure){$note .= qq!<tr><td>Vital Signs:</td><td>Blood Pressure:$Blood_pressure;  !;}
  if ($Heart_rate){$note .= qq!Heart Rate: $Heart_rate;  !;}
  if ($Resp_rate){$note .= qq!Respiratory Rate: $Resp_rate;  !;}
  if ($Temp){$note .= qq!Temperature: $Temp;  !;}
  if ($Blood_glucose){$note .= qq!Blood Glucose: $Blood_glucose;  !;}
  if ($Height){$note .= qq!Height: $Height;  !;}
  if ($Weight){$note .= qq!Weight: $Weight;  !;}
  if ($Blood_pressure || $Heart_rate || $Resp_rate || $Temp || $Blood_glucose || $Height || $Weight){
    $note =~ s/;  $/.<\/td><\/tr>/;
  }
  if ($General_exam){$note .= qq!<tr><td>General Exam:</td><td>$General_exam</td></tr>!;}
  if ($Skin_exam){$note .= qq!<tr><td>Skin Exam:</td><td>$Skin_exam</td></tr>!;}
  if ($Eye_exam){$note .= qq!<tr><td>Eye Exam:</td><td>$Eye_exam</td></tr>!;}
  if ($Ear_exam){$note .= qq!<tr><td>Ear Exam:</td><td>$Ear_exam</td></tr>!;}
  if ($Nose_exam){$note .= qq!<tr><td>Nose Exam:</td><td>$Nose_exam</td></tr>!;}
  if ($Mouth_exam){$note .= qq!<tr><td>Mouth Exam:</td><td>$Mouth_exam</td></tr>!;}
  if ($Neck_exam){$note .= qq!<tr><td>Neck Exam:</td><td>$Neck_exam</td></tr>!;}
  if ($Thyroid_exam){$note .= qq!<tr><td>Thyroid Exam:</td><td>$Thyroid_exam</td></tr>!;}
  if ($Lymph_exam){$note .= qq!<tr><td>Lymph Exam:</td><td>$Lymph_exam</td></tr>!;}
  if ($Chest_exam){$note .= qq!<tr><td>Chest Exam:</td><td>$Chest_exam</td></tr>!;}
  if ($Lung_exam){$note .= qq!<tr><td>Lung Exam:</td><td>$Lung_exam</td></tr>!;}
  if ($Heart_exam){$note .= qq!<tr><td>Heart Exam:</td><td>$Heart_exam</td></tr>!;}
  if ($Breast_exam){$note .= qq!<tr><td>Breast Exam:</td><td>$Breast_exam</td></tr>!;}
  if ($Abdomen_exam){$note .= qq!<tr><td>Abdomen Exam:</td><td>$Abdomen_exam</td></tr>!;}
  if ($Rectal_exam){$note .= qq!<tr><td>Rectal Exam:</td><td>$Rectal_exam</td></tr>!;}
  if ($Prostate_exam){$note .= qq!<tr><td>Prostate Exam:</td><td>$Prostate_exam</td></tr>!;}
  if ($Testespenis_exam){$note .= qq!<tr><td>Testes/Penis Exam:</td><td>$Testespenis_exam</td></tr>!;}
  if ($External_female_exam){$note .= qq!<tr><td>External Female Genital Exam:</td><td>$External_female_exam</td></tr>!;}
  if ($Speculum_exam){$note .= qq!<tr><td>Speculum Exam:</td><td>$Speculum_exam</td></tr>!;}
  if ($Internal_exam){$note .= qq!<tr><td>Internal Exam:</td><td>$Internal_exam</td></tr>!;}
  if ($Extremities_exam){$note .= qq!<tr><td>Extremities Exam:</td><td>$Extremities_exam</td></tr>!;}
  if ($Pulses_exam){$note .= qq!<tr><td>Pulses Exam:</td><td>$Pulses_exam</td></tr>!;}
  if ($Neurologic_exam){$note .= qq!<tr><td>Neurologic Exam:</td><td>$Neurologic_exam</td></tr>!;}
  if ($General_exam || $Skin_exam || $Eye_exam || $Ear_exam || $Nose_exam || $Mouth_exam || $Neck_exam || $Thyroid_exam || $Lymph_exam || $Chest_exam || $Lung_exam || $Heart_exam || $Breast_exam || $Abdomen_exam || $Rectal_exam || $Prostate_exam || $Testespenis_exam || $External_female_exam || $Speculum_exam || $Internal_exam || $Extremities_exam || $Pulses_exam || $Neurologic_exam){
    $note .= qq!</table></td></tr><tr><td colspan=8><table>!;
  }
  if ($assessment_plan){
    $assessment_plan =~ s/(.*)\[(.*)\]/<b>$1$2<\/b>/mg;
    $assessment_plan =~ s/\n/<br>/sg;
    $assessment_plan =~ s/Assessment/<i>Assessment<\/i>/sg;
    $assessment_plan =~ s/Plan/<i>Plan<\/i>/sg;
    $assessment_plan =~ s/Health Maintenance/<b>Health Maintenance<\/b>/sg;
    $assessment_plan =~ s/Additional Note/<b>Additional Note<\/b>/sg;
    $note .= qq!<tr><th align=LEFT><h3>Assessment and Plan:</h3></th></tr>
<tr><td>$assessment_plan</td></tr></table>!;
  }
  return $note;
}

###################################################################################################
##  Subroutine:  Search for medications by trade name

sub Trade_Name_Search {
  my ($trade_name_search, $problem_id);
  ($trade_name_search, $problem_id)  = @_;
  my ($sql, $sth, $arrayref, $ref, $c, $key, $listing_seq_no, $trade_name, $ingredient_name, $strength, $unit, $new_med);
  my (@list, @values, %distinct, %routes);
  $sql         = qq!SELECT DISTINCT listings.listing_seq_no, listings.trade_name, formulat.ingredient_name, formulat.strength, formulat.unit 
                    FROM listings LEFT JOIN formulat ON listings.listing_seq_no=formulat.listing_seq_no 
                    WHERE ((trade_name REGEXP "$trade_name_search") AND (formulat.strength>0)) 
                    ORDER BY trade_name, strength DESC!;
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
    while ($ref= $sth->fetch){
      $routes{$key.", ".@$ref[0]."[".$distinct{$key}."]".$problem_id}=$key.", ".@$ref[1];       # This produces an hash named routes;
    }                                                                                             # the keys are the distinct formulations with route_code and problem_id attached, 
  }                                                                                               # the values are the route_name.
  $new_med      = qq!<td>!;
  $new_med     .= $cgi->scrolling_list(-name=>'Medication Name', 
				      -size=>'10', 
				      -values=>[keys %routes], 
				      -labels=>\%routes);
  $new_med    .= qq!</td><td><select name="Medication Frequency">
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
<option value='Once Monthly'>Once Monthly</option>
</select></td>!;
  $new_med    .= qq!<td><input type="submit" name="SubmitButton" value='Add Medication')</td>!;
  return $new_med;
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
				$routes{$key.", ".@$ref[0]."[".$distinct{$key}."]".$problem_id}=$key.", ".@$ref[1];    # the keys are the distinct formulations with route_code and problem_idattached, 
			}                                                                                          # the values are the route_name.
		}
		$new_med      = qq!<td>!;
		$new_med     = $cgi->scrolling_list(-name=>'Medication Name', 
											-size=>'10',
											-values=>[keys %routes], 
											-labels=>\%routes);
		$new_med    .= qq!</td><td><select name="Medication Frequency">
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
			<option value='Once Monthly'>Once Monthly</option>
			</select></td>!;
		$new_med    .= qq!<td><input type="submit" name="SubmitButton" value='Add Medication')</td>!;
return $new_med;
}

###################################################################################
## Search for tests

sub Test_Search {
	my $class = $_[0];
	my $problem_id = $_[1];
	my $method_typ = $_[2];
	my $system = $_[3];
	my ($sql, $sth, $loinc_num, $component, $shortname, $species, $return);
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
						<td><select name="Test Class" size=10>!;
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
					if ($method_typ && $system){
						if ($method_typ eq "empty"){$method_typ = "";}
						$sql = qq!SELECT DISTINCT loinc_num, component, shortname
						FROM loinc
						WHERE (class="$class" AND method_typ LIKE "$method_typ%" AND system LIKE "$system%") ORDER by shortname ASC!;
						$sth = $dbh ->prepare($sql);
						$sth -> execute;
						$sth ->bind_columns(\($loinc_num, $component, $shortname));
						$return = qq!<tr><td><input type="submit" name="SubmitButton" value="Pick Observation"</td>
							<td><select name="Test Ordered" size=10>!;
						if ($method_typ eq ""){$method_typ = "empty";}
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
################# Given class and method type, get list of systems covered
					elsif ($method_typ){
						if ($method_typ eq "empty"){$method_typ = "";}
						$sql = qq!SELECT DISTINCT system
						FROM loinc
						WHERE (class="$class" AND method_typ LIKE "$method_typ%") ORDER by system ASC!;
						$sth = $dbh ->prepare($sql);
						$sth -> execute;
						$sth ->bind_columns(\($system));
						$return = qq!<tr><td><input type="submit" name="SubmitButton" value="Pick System"</td>
							<td><select name="Test System" size=10>!;
						if ($method_typ eq ""){$method_typ = "empty";}
						while ($sth->fetch){
#							if ($system =~ /(.*)\.(.*)/){
#								$system = $1;
#								$species = "($2)";
#							}
							if ($SYSTEM{$system}){
								$return .= qq!<option value="$class $method_typ $system">$SYSTEM{$system} $species</option>!;
							}
							else {
								$return .= qq!<option value="$class $method_typ $system">$system $species</option>!;
							}
						}
						$return.= qq!</select></td></tr>!;
					}
################ Given class, get list of method types
					else {
						$sql = qq!SELECT DISTINCT method_typ
						FROM loinc
						WHERE class="$class" ORDER by method_typ ASC!;
						$sth = $dbh ->prepare($sql);
						$sth -> execute;
						$sth ->bind_columns(\($method_typ));
						$return = qq!<tr><td><input type="submit" name="SubmitButton" value="Pick Method"</td>
							<td><select name="Test Method" size=10>!;
						while ($sth->fetch){
							if ($METHOD{$method_typ}){
								$return .= qq!<option value="$class $method_typ">$METHOD{$method_typ}</option>!;
							}
							elsif ($method_typ) {
								$return .= qq!<option value="$class $method_typ">$method_typ</option>!;
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
  my ($patient_info, $title, $fname, $lname, $DOB, $sex, $month, $day, $year, $sql, $sth);
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
    $DOB =~  s/(\d*)-(\d*)-(\d*)/$2\/$3\/$1/;
    $patient_info = td({-align=>LEFT, -colspan=>'3'},b("Patient Name: "), $title, " ",$fname, " ", $lname).
      td({-align=>LEFT, -colspan=>'3'},b("DOB: "), $DOB).
	td({-align=>LEFT, -colspan=>'2'},b("Visit Date: "), $month."/".$day."/".$year);
  }
  return $patient_info, $DOB, $sex;
}

###################################################################################
## Get Todays Problem List
## Input: Passed in by param()
## Output: $page

sub Get_Todays_Problem_List {
  my $patient_id = shift;
  my ($page, $problem_id, $id, $concept, $code, $date_added, $active, $chronic, $year, $month, $day, $sql, $sth);
  my (@past, @chronic, @ongoing, @acute, @active);
  ################################################ Add New Problem to Problem List
  if (param('SubmitButton') eq 'Add New Problem'){
    $page .= qq!<input type="text" name="Problem Text Search" /><input type="submit" name="SubmitButton" value="Search for Problem" /><br>
<select name="Type of Problem">
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
              WHERE concept REGEXP '".param('Problem Text Search')."' 
              ORDER BY code";
    $sth = $dbh->prepare($sql);
    $sth->execute;
    $sth ->bind_columns(\($id, $concept, $code));
    $page .= qq!<select name='Choose Problem'> !;
    while ($sth->fetch){
      $page .= qq!<option value="$id">$concept</option> !;
    }
    $page .= qq!</select><input type="submit" name="SubmitButton" value="Choose This Problem" /><hr>!;
  }
  ################################################  Put problems into database
  else{
    if (param('Choose Problem')){
      $sql = "INSERT into problem_list (patient_id, date_added, provider_id, problem_id, active, chronic) 
                VALUES('".$patient_id."', '".todays_date()."', '".param('provider_id')."', '".param('Choose Problem')."', '1', '".param('Problem Text Search')."')";
      $sth = $dbh->prepare($sql);
      $sth->execute;
    }
    ################################################  Get Todays Problems
    $sql   = qq!SELECT problem_list.problem_id, concept, code, date_added, active, chronic 
                  FROM problem_list LEFT JOIN icd_9_cm_concepts ON problem_list.problem_id=icd_9_cm_concepts.id 
                  WHERE patient_id="$patient_id"!;
    $sth = $dbh->prepare($sql);
    $sth ->execute;
    $sth ->bind_columns(\($problem_id, $concept, $code, $date_added, $active, $chronic));
    while ($sth->fetch){
      $date_added =~ s/(\d+)-(\d+)-(\d+)/$2\/$3\/$1/;
      if ($active == 1){$active = "Active";}else{$active = "Inactive";}
      if ($chronic == 3){
	push (@past, [$problem_id, $concept, $code, $date_added, $active]);
      }
      if ($chronic == 2){
	push (@chronic, [$problem_id, $concept, $code, $date_added, $active]);
      }
      elsif ($chronic == 1){
	push (@ongoing, [$problem_id, $concept, $code, $date_added, $active]);
      }
      elsif ($chronic == 0){
	push (@acute, [$problem_id, $concept, $code, $date_added, $active]);
      }
    }
    if (@past || @chronic || @ongoing || @acute){
      $page .= qq!<input type="submit" name="SubmitButton" value="Select Problems"><br>
<select name='Todays Problems' size='10' multiple='1'> !;
      my $index = 0;
      $page .= qq!<option disabled="disabled" value=""> -- Past Problems -- </option>!;
      for ($index = 0; $index<=$#past; $index++){
	$page .= qq!<option value="$past[$index][0]">$past[$index][1] $past[$index][2] Date Added:$past[$index][3] Active:$past[$index][4]</option>!;
      }
      $page .= qq!<option disabled="disabled" value=""> -- Chronic Problems -- </option>!;
      for ($index = 0; $index<=$#chronic; $index++){
	$page .= qq!<option value="$chronic[$index][0]">$chronic[$index][1] $chronic[$index][2] Date Added:$chronic[$index][3] Active:$chronic[$index][4]</option>!;
      }
      $page .= qq!<option disabled="disabled" value=""> -- Ongoing Problems -- </option>!;
      for ($index = 0; $index<=$#ongoing; $index++){
	$page .= qq!<option value="$ongoing[$index][0]">$ongoing[$index][1] $ongoing[$index][2] Date Added:$ongoing[$index][3] Active:$ongoing[$index][4]</option>!;
      }
      $page .= qq!<option disabled="disabled" value=""> -- Acute Problems -- </option>!;
      for ($index = 0; $index<=$#acute; $index++){
	$page .= qq!<option value="$acute[$index][0]">$acute[$index][1] $acute[$index][2] Date Added:$acute[$index][3] Active:$acute[$index][4]</option>!;
      }
      $page .= qq!</select><br> !;
    }
    else {
      $page .= "No past problems noted.  Please add Todays Problem(s).";
    }
    $page .= qq!<input type="submit" name="SubmitButton" value="Add New Problem"> !;
  }
  return $page;
}

#############################################################################################
## Form to fill out in order to produce note

sub Note_Format {
  my $patient_id = shift;
  my (@problem_id, $page, $patient_info, $sql, $sth, @concept, @date_added, $DOB, $sex);
  ###############################################  Patient Information and Chief Compaint
  @problem_id = param('Todays Problems');
  $page .= qq!<input type="hidden" name="Problem List" value="@problem_id">
<table width="100%" bgcolor="grey">!;
  ($patient_info, $DOB, $sex) = Get_Patient_Info($patient_id);
  $page .= qq!<tr>$patient_info</tr>
<tr><th colspan="3" align=LEFT>Chief Complaint</th></tr>!;
  foreach(@problem_id){
    $sql   = qq!SELECT icd_9_cm_concepts.concept, date_added 
                FROM problem_list LEFT JOIN icd_9_cm_concepts ON problem_list.problem_id=icd_9_cm_concepts.id 
                WHERE problem_list.patient_id=? and problem_list.problem_id=?! ;
    $sth = $dbh->prepare($sql);
    $sth->bind_param(1, $patient_id);
    $sth->bind_param(2, $_);
    $sth ->execute;
    $sth ->bind_columns(\($concept[$_], $date_added[$_]));
    while ($sth->fetch){
      $concept[$_] =~ s/(^.*\[.*\]).*/$1/;
      $date_added[$_]=~ s/(\d+)-(\d+)-(\d+)/$2\/$3\/$1/;
      $page .= qq!<tr><td>$concept[$_] First Noted: $date_added[$_]</td></tr>!;
    }
  }
  ##############################################  HPI
  
  $page .=    qq!<tr><td colspan="8"><fieldset><label>History of Present Illness</label><table>!;
  foreach (@problem_id){
    if ($concept[$_] =~ /\[V.*/){
      $page .=qq!<tr><td><b>$concept[$_]</b></td></tr>
<tr><td>Particular Concerns</td>
<td><textarea name="$_ concerns" rows="2" cols="75"></textarea></td></tr>!;
    }
    else{
      $page .=qq!<tr><td colspan="2"><b>$concept[$_]</b></td>
<tr><td>Location</td>
<td><textarea name="$_ Location"  rows="2" cols="75"></textarea></td></tr>
<tr><td>Quality</td>
<td><textarea name="$_ Quality"  rows="2" cols="75"></textarea></td></tr>
<tr><td>Quantity/Severity</td>
<td><textarea name="$_ Quantity"  rows="2" cols="75"></textarea></td></tr>
<tr><td>Timing<br> (Onset, Duration, Frequency)</td>
<td><textarea name="$_ Timing"  rows="2" cols="75"></textarea></td></tr>
<tr><td>Setting<br>Context</td>
<td><textarea name="$_ Setting"  rows="2" cols="75"></textarea></td></tr>
<tr><td>Aggravating/Relieving</td>
<td><textarea name="$_ Aggravating Relieving"  rows="2" cols="75"></textarea></td></tr>
<tr><td>Associated Signs and Symptoms</td>
<td><textarea name="$_ Associated Manifestations"  rows="2" cols="75"></textarea></td></tr>
<tr><td>Patient's Reaction<br>Effect on Life</td>
<td><textarea name="$_ Patient Reaction" rows="2" cols="75"></textarea></td</tr>!;
    }
  }
  $page .= qq!<tr><td><input type="checkbox" name="Reviewed and summarized old patient chart">Reviewed and summarized old patient chart</td>
<td><input type="checkbox" name="Obtained history from someone other than patient">Obtained history from someone other than patient</td></tr>
</FIELDSET></table></td></tr>
<tr><td colspan="8"><FIELDSET><label>Review of Systems</label><table>!;
  #<tr></td><input type="submit" name="SubmitButton" value="Full Review of Systems"></td></tr>
  $page .= qq!<tr><td colspan="1" align=LEFT><b>Any Pain</b>
<Select name="Pain">
<option value=""></option>
<option value="Yes">Yes</option>
<option value="No">No</option>
</select></td>
<td colspan="1" align=LEFT>Pain Scale
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
<td colspan="6" align=LEFT>Pain Location<input type=text name="Pain Location" size=20 /></td></tr>!;
  #    if (param('SubmitButton') eq 'Full Review of Systems'){
  $page .= qq!<tr align=LEFT><th>General</th><th>Skin</th><th>Head</th><th>Eyes</th><th>Ears</th><th>Nose<br>Sinuses</th><th>Mouth<br>Throat</th></tr>
<tr valign=TOP>
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
</select></td></tr>
<tr><th>Neck</th><th>Breasts</th><th>Respiratory</th><th>Cardiac</th><th>GI</th><th>Urinary</th>!;
  if ($sex eq 'M'){$page .="<th>Male Genital</th><th></th></tr>";}
  if ($sex eq 'F'){$page .="<th>Female Genital</th><th></th></tr>";}
  $page .= qq!<td><select name="Neck" multiple="multiple" default="normal" size="5">
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
</select></td>
<td><select name="Cardiac" multiple="multiple" default="normal" size="5">
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
    $page .= qq!<td><select name="Male Genital" multiple="multiple" default="normal" size="5" >
<option value="normal">normal</option>
<option value="nernia">hernia</option>
<option value="discharge from penis">discharge from penis</option>
<option value="sore on penis">sore on penis</option>
<option value="testicular pain">testicular pain</option>
<option value="testicular mass">testicular mass</option>
</select></td></tr>!;
  }
  if ($sex eq 'F'){
    $page .= qq!<td><select name="Female Genital" multiple="multiple" default="normal" size="5" >
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
</select></td></tr>!;
  }
  $page .= qq!<tr align=LEFT><th>Peripheral Vascular</th><th>Neurologic</th><th>Musc-Skel</th><th>Endo</th><th>Heme</th><th>Psyche</th><th></th></tr>
<tr valign=TOP>
<td><select name="Peripheral Vascular" multiple="multiple" default="normal" size="5" >
<option value="normal">normal</option>
<option value="intermittent claudication">intermit claud</option>
<option value="leg cramps">leg cramps</option>
<option value="varicose veins">varicose veins</option>
<option value="swelling in left leg">swell in l leg</option>
<option value="swelling in right leg">swell in r leg</option>
<option value="cold feet">cold feet</option>
</select></td>
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
</select></td><td></td><td></td></tr>!;
#}
  $page .= qq!<tr><th colspan="1"  align=LEFT>Other Pertinent Symptoms</th>
<td colspan="7"><input type=text name="Other Symptoms" size="100" /></td></tr>
</table></FIELDSET></td></tr>!;
  ############################### Add Past/Family/Social History
  my $last_social_history;
  $sql = qq!SELECT last_social_history 
              FROM history_data 
              WHERE pid="$patient_id"!;
  $sth = $dbh->prepare($sql);
  $sth ->execute;
  $sth ->bind_columns(\$last_social_history);
  $page .=  qq!<tr><td colspan="8"  align=TOP><FIELDSET><label>Past Medical, Family and Social History</label><table>!;
  if ($sth->fetch){
    $page .= qq!<tr><td>Unchanged from visit date $last_social_history</td></tr>!;
  }
  $page .= qq!</td></tr>
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
  
  my (@chronic, @ongoing, @acute, @past);
  ############################### Get Past History
  my ($id, $coffee, $alcohol, $drug_use, $sleep_patterns, $exercise_patterns, $std, $reproduction, $sexual_function, $self_breast_exam, $self_testicle_exam, $seatbelt_use, $counseling, $hazardous_activities, $last_breast_exam, $last_mammogram, $last_gynocological_exam, $last_psa, $last_prostate_exam, $last_physical_exam, $last_sigmoidoscopy_colonoscopy, $last_fecal_occult_blood, $last_ppd, $last_bone_density, $history_mother, $history_father, $history_siblings, $history_offspring, $history_spouse, $relatives_cancer, $relatives_tuberculosis, $relatives_diabetes, $relatives_hypertension, $relatives_heart_problems, $relatives_stroke, $relatives_epilepsy, $relatives_mental_illness, $relatives_suicide, $date, $pid, $name_1, $value_1, $name_2, $value_2, $additional_history, $concept, $date_added, $code, $active, $chronic);
  $sql = qq!SELECT id, coffee, alcohol, drug_use, sleep_patterns, exercise_patterns, std, reproduction, sexual_function, self_breast_exam, self_testicle_exam, seatbelt_use, counseling, hazardous_activities, last_social_history, last_breast_exam, last_mammogram, last_gynocological_exam, last_psa, last_prostate_exam, last_physical_exam, last_sigmoidoscopy_colonoscopy, last_fecal_occult_blood, last_ppd, last_bone_density, history_mother, history_father, history_siblings, history_offspring, history_spouse, relatives_cancer, relatives_tuberculosis, relatives_diabetes, relatives_hypertension, relatives_heart_problems, relatives_stroke, relatives_epilepsy, relatives_mental_illness, relatives_suicide, date, pid, name_1, value_1, name_2, value_2, additional_history 
                FROM history_data
                WHERE pid="$patient_id"!;
  $sth = $dbh->prepare($sql);
  $sth ->execute;
  $sth ->bind_columns(\($id, $coffee, $alcohol, $drug_use, $sleep_patterns, $exercise_patterns, $std, $reproduction, $sexual_function, $self_breast_exam, $self_testicle_exam, $seatbelt_use, $counseling, $hazardous_activities, $last_social_history, $last_breast_exam, $last_mammogram, $last_gynocological_exam, $last_psa, $last_prostate_exam, $last_physical_exam, $last_sigmoidoscopy_colonoscopy, $last_fecal_occult_blood, $last_ppd, $last_bone_density, $history_mother, $history_father, $history_siblings, $history_offspring, $history_spouse, $relatives_cancer, $relatives_tuberculosis, $relatives_diabetes, $relatives_hypertension, $relatives_heart_problems, $relatives_stroke, $relatives_epilepsy, $relatives_mental_illness, $relatives_suicide, $date, $pid, $name_1, $value_1, $name_2, $value_2, $additional_history));
  
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
  }
  $sql = qq!SELECT sex
              FROM patient_data
              WHERE pid="$patient_id"!;
  $sth = $dbh->prepare($sql);
  $sth ->execute;
  $sth->bind_columns(\$sex);
  $sth->fetch;
  if (@past){
    $page .= qq!<tr><td colspan="8"><label for="Past Medical History">Past Medical History</label>!;
    $page .= qq!<textarea name="Past Medical History" rows=$#past cols="100">!;
    foreach (@past){$page .= qq!   $_\n!;}
    $page .= qq!</textarea></td></tr>!;
  } else {$page .= qq!<tr><th align=LEFT>No significant Past Medical History noted.</th><td colspan=2><input type=text name="Past Medical History" /></td></tr>!;}
  $page .= qq!<tr><td colspan="8"><fieldset><label>Social History</label><table>!;
  $page .= qq!<tr><th align=RIGHT>Coffee Use</th>!;if ($coffee ){$page .= qq!<td>$coffee</td>!;}$page.=qq!<td><input type=text name="coffee" /></td>!;
  $page .= qq!<th align=RIGHT>Alcohol Use</th>!;if ( $alcohol ){$page.=qq!<td>$alcohol</td>!;}$page .= qq!<td><input type=text name="alcohol" /></td>!;
  $page .= qq!<th align=RIGHT>Drug Use</th>!;if ( $drug_use ){$page .= qq!<td>$drug_use</td>!;}$page.=qq!<td><input type=text name="drug" /></td>!;
  $page .= qq!<th align=RIGHT>Sleep patterns</th>!;if ( $sleep_patterns ){$page .= qq!<td>$sleep_patterns</td>!;}$page.=qq!<td><input type=text name="sleep_patterns" /></td>!;
  $page .= qq!<th align=RIGHT>Exercise patterns</th>!;if ( $exercise_patterns ){$page.=qq!<td>$exercise_patterns</td></tr>!;}$page .= qq!<td><input type=text name="exercise_patterns" /></td></tr>!;
  $page .= qq!<tr><th align=RIGHT>Sexually Transmitted Disease</th>!;if ( $std ){$page.=qq!<td>$std</td>!;}$page .= qq!<td><input type=text name="std" /></td>!;
  $page .= qq!<th align=RIGHT>Reproduction</th>!;if ( $reproduction ){$page.=qq!<td>$reproduction</td>!;}$page .= qq!<td><input type=text name="reproduction" /></td>!;
  $page .= qq!<th align=RIGHT>Sexual Function</th>!;if ( $sexual_function ){$page .=qq!<td>$sexual_function</td>!;}$page .= qq!<td><input type=text name="sexual_function" /></td>!;
  if($sex eq 'F'){
    $page .= qq!<th align=RIGHT>Self Breast Exam</th>!;
    if ( $self_breast_exam ){$page.=qq!<td>$self_breast_exam</td>!;}
    $page .= qq!<td><input type=text name="self_breast_exam" /></td>!;
  }
  if($sex eq'M'){
    $page .= qq!<th align=RIGHT>Self Testicle Exam</th>!;
    if ( $self_testicle_exam ){$page.=qq!<td>$self_testicle_exam</td>!;}
    $page .= qq!<td><input type=text name="self_testicle_exam" /></td>!;
  }
  $page .= qq!<th align=RIGHT>Seatbelt Use</th>!;if ( $seatbelt_use ){$page .=qq!<td>$seatbelt_use</td></tr>!;}$page .= qq!<td><input type=text name="seatbelt_use" /></td></tr>!;
  $page .= qq!<tr><th align=RIGHT>Counseling</th>!;if ( $counseling ){$page.=qq!<td>$counseling</td>!;}else{$page .= qq!<td><input type=text name="counseling" /></td>!;}
  $page .= qq!<th align=RIGHT>Hazardous Activities</th>!;if( $hazardous_activities ){$page.=qq!<td>$hazardous_activities</td>!;}$page .= qq!<td><input type=text name="hazardous_activities" /></td></tr>!;
  $page .= qq!</table></fieldset></td</tr><tr><td colspan="8"><fieldset><label>Family History</label><table>!;
  $page .= qq!<tr><th align=RIGHT>Mother's Medical History</th>!;if ( $history_mother ){$page.=qq!<td>$history_mother</td>!;}$page .=qq!<td><input type=text name="history_mother" /></td>!;
  $page .= qq!<th align=RIGHT>Father's Medical History</th>!;if ( $history_father ){$page.=qq!<td>$history_father</td>!;}$page .=qq!<td><input type=text name="history_father" /></td>!;
  $page .= qq!<th align=RIGHT>Sibling's Medical History</th>!;if ( $history_siblings ){$page.=qq!<td>$history_siblings</td>!;}$page .=qq!<td><input type=text name="history_siblings" /></td>!;
  $page .= qq!<th align=RIGHT>Offspring's Medical History</th>!;if ( $history_offspring ){$page.=qq!<td>$history_offspring</td>!;}$page .=qq!<td><input type=text name="history_offspring" /></td>!;
  $page .= qq!<th align=RIGHT>Spouse's Medical History</th>!;if ( $history_spouse ){$page.=qq!<td>$history_spouse</td>!;}$page .=qq!<td><input type=text name="history_spouse" /></td></tr>!;
  $page .= qq!<tr><th align=RIGHT>Relative's Cancer History</th>!;if ( $relatives_cancer ){$page.=qq!<td>$relatives_cancer</td>!;}$page .=qq!<td><input type=text name="relatives_cancer" /></td>!;
  $page .= qq!<th align=RIGHT>Relative's Tuberculosis History</th>!;if ( $relatives_tuberculosis ){$page.=qq!<td>$relatives_tuberculosis</td>!;}$page .=qq!<td><input type=text name="relatives_tuberculosis" /></td>!;
  $page .= qq!<th align=RIGHT>Relative's Diabetes History</th>!;if ( $relatives_diabetes ){$page.=qq!<td>$relatives_diabetes</td>!;}$page .=qq!<td><input type=text name="relatives_diabetes" /></td>!;
  $page .= qq!<th align=RIGHT>Relative's Hypertension History</th>!;if ( $relatives_hypertension ){$page.=qq!<td>$relatives_hypertension</td>!;}$page .=qq!<td><input type=text name="relatives_hypertension" /></td>!;
  $page .= qq!<th align=RIGHT>Relative's Heart Problems History</th>!;if ( $relatives_heart_problems ){$page.=qq!<td>$relatives_heart_problems</td>!;}$page .=qq!<td><input type=text name="relatives_heart_problems" /></td></tr>!;
  $page .= qq!<tr><th align=RIGHT>Relative's Stroke History</th>!;if ( $relatives_stroke ){$page.=qq!<td>$relatives_stroke</td>!;}$page .=qq!<td><input type=text name="relatives_stroke" /></td>!;
  $page .= qq!<th align=RIGHT>Relative's Epilepsy History</th>!;if ( $relatives_epilepsy ){$page.=qq!<td>$relatives_epilepsy</td>!;}$page .=qq!<td><input type=text name="relatives_epilepsy" /></td>!;
  $page .= qq!<th align=RIGHT>Relative's Mental Illness History</th>!;if ( $relatives_mental_illness ){$page.=qq!<td>$relatives_mental_illness</td>!;}$page .=qq!<td><input type=text name="relatives_mental_illness" /></td>!;
  $page .= qq!<th align=RIGHT>Relative's Suicide History</th>!;if ( $relatives_suicide ){$page.=qq!<td>$relatives_suicide</td>!;}$page .=qq!<td><input type=text name="relatives_suicide" /></td>!;
  $page .= qq!</table></fieldset></td></tr>!;
  
  ###########################################  Physical Exam
  $page .=   qq!</table></fieldset></td></tr>
<tr><td colspan="8"  align=TOP><FIELDSET><label>Physical Exam</label><table>
<tr><td>BP<input type=text name="Blood Pressure" size="7" /></td>
<td>HR<input type=text name="Heart Rate" size ="3" /></td>
<td>RR<input type=text name="Respiratory Rate" size="2" /></td>
<td>Temp<input type=text name="Temperature" size="3" /></td>
<td>FS<input type=text name="Blood Glucose" size="3" /></td>
<td>Ht<input type=text name="Height" size="7" /></td>
<td>Wt<input type=text name="Weight" size="3" /></td></tr>
<tr><th>General</th><th>Skin</th><th>Eye</th><th>Ear</th><th>Nose</th><th>Mouth</th><th>Neck</th></tr>
<tr><td><select name="General Exam" multiple="multiple" default="normal" size="5">
<option value=""></option>
<option value="well nourished and groomed">Well nourished,groomed</option>
<option value="ambulatory">Ambulatory</option>
<option value="no apparent distress">NAD</option>
<option value="no weight loss">No weight loss</option>
</select></td>
<td><select name="Skin Exam" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="no rash">No Rash</option>
<option value="no lesions">No Lesions</option>
<option value="no suspicious moles">No Suspic Moles</option>
</select></td>
<td><select name="Eye Exam" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="pupils equal, round, reactive to light and accomodation">PERRLA</option>
<option value="no hematorrhages or exudates in fundi">No H,E in Fundi</option>
</select></td>
<td><select name="Ear Exam" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="tympanic membrane intact">TM Intact</option>
<option value="no erythema">No Eryth</option>
<option value="Rinne normal (AC>BC)">Norm Rinne</option>
<option value="Weber midline">Weber mid</option>
</select></td>
<td><select name="Nose Exam" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="mucosa pink">Mucosa pink</option>
<option value="septum midline">Septum mid</option>
<option value="no sinus tenderness">No sinus tender</options>
</select></td>
<td><select name="Mouth Exam" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="mucosa pink">Mucosa pink</option>
<option value="no dental carries">no carries</option>
<option value="no lesions">no lesions</option>
<option value=""></option>
</select></td>
<td><select name="Neck Exam" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="no erythema">no eryth</option>
<option value="no exudates">no exud</option>
<option value="no jugular venous distension">no JVD</option>
<option value="no palpable lymph nodes">no palp LN</option>
<option value="trachea midline">trach mid</option>
<option value="no bruits">no bruits</option>
</select></td></tr>
<tr><td><input type=text name="General Exam Text" size="20" /></td>
<td><input type=text name="Skin Exam Text" size="20" /></td>
<td><input type=text name="Eye Exam Text" size="20" /></td>
<td><input type=text name="Ear Exam Text" size="20" /></td>
<td><input type=text name="Nose Exam Text" size="20" /></td>
<td><input type=text name="Mouth Exam Text" size="20" /></td>
<td><input type=text name="Neck Exam Text" size="20" /></td>
</tr>
<tr><th>Thyroid</th><th>Lymph Node</th><th>Chest</th><th>Lungs</th><th>Heart</th><th>Breasts</th><th>Abdomen</th><th></th></tr>
<tr><td><select name="Thyroid Exam" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="no thyromegaly">no thyromegaly</option>
<option value="no thyroid nodules">no thyroid nodules</option>
</select></td>
<td><select name="Lymph Node Exam" multiple="multiple" default="normal" size="5">
<option value="no submandibular lymph nodes">no Sub Man</option>
<option value="no cervical lymph nodes">no Cerv</option>
<option value="no supraclavicular lymph nodes">no Super Clav</option>
<option value="no axillary lymph nodes">no axil</option>
<option value="no epitrochlear lymph nodes">no epitroch</option>
<option value="no hepatomegaly">no hepat</option>
<option value="no splenomegaly">no spleno</option>
<option value="no inguinal lymph nodes">no inguin</option>
</select></td>
<td><select name="Chest Exam" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="thorax symmetrical">thorax symmetrical</option>
<option value="ribs not tender">no tender ribs</option>
<option value="no costophrenic angle tenderness">no cva</option>
<option value=""></option>
</select></td>
<td><select name="Lungs Exam" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="clear to auscultation">cta</option>
<option value="normal fremitus">normal fremitus</option>
<option value="no crackles">no crackles</option>
<option value="no wheezes">no wheezes</option>
<option value="no stridor">no stridor</option>
<option value="no pleural rub">no rub</option>
</select></td>
<td><select name="Heart Exam" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="regular rate and rhythm">rrr</option>
<option value="no murmurs, rubs or gallops">no mrg</option>
<option value="apical impulse in fifth intercostal space at mid-clavicular line">nl impulse</option>
<option value=""></option>
<option value=""></option>
</select></td>
<td><select name="Breasts Exam" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="no edema">no edema</option>
<option value="no skin dimpling">no dimpl</option>
<option value="no nipple retraction">no nipl retr</option>
<option value="bilaterally symmetrical">sym</option>
<option value="no nipple discharge">no disch</option>
</select></td>
<td><select name="Abdomen Exam" multiple="multiple" default="normal" size="5">
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
<tr><td><input type=text name="Thyroid Exam Text" size="20" /></td>
<td><input type=text name="Lymph Node Exam Text" size="20" /></td>
<td><input type=text name="Chest Exam Text" size="20" /></td>
<td><input type=text name="Lungs Exam Text" size="20" /></td>
<td><input type=text name="Heart Exam Text" size="20" /></td>
<td><input type=text name="Breast Exam Text" size="20" /></td>
<td><input type=text name="Abdomen Exam Text" size="20" /></td></tr>
<tr><th>Rectal</th>!;
  if ($sex eq 'M'){$page .="<th>Prostate</th><th>Testes<br>Penis</th>";}
  if ($sex eq 'F'){$page .="<th>External Female Genital</th><th>Speculum</th><th>Internal</th>";}
  $page .= qq!<th>Extremities</th><th>Pulses</th><th>Neurologic</th></tr>
<tr><td><select name="Rectal Exam" multiple="multiple" default="normal" size="5">
<option value="normal">Normal</option>
<option value="no masses">no mass</option>
<option value="stool guiac negative">guiac neg</option>
<option value="no fissures">no fissures</option>
<option value="no hemarrhoids">no hemarrhoids</option>
<option value="no fistulas">no fistulas</option>
<option value="no splenomegaly">no spleno</option>
</select></td>!;
  if ($sex eq 'M'){
    $page .=     qq!<td><select name="Prostate Exam" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="no mass">no mass</option>
<option value="no enlargement">no enlarge</option>
<option value="no tenderness">no tender</option>
</select></td>
<td><select name="Testes, Penis Exam" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="no masses">no mass</option>
<option value="no lesions">no lesions</option>
<option value="no discharge">no disch</option>
<option value="no testicular nodules">no test nod</option>
<option value="no hernia">no hernia</option>
</select></td>!;
  }
  if ($sex eq 'F'){
    $page .=     qq!<td><select name=External Female Genital" Exam" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="no inflamation">no infl</option>
<option value="no ulceration">no ulcer</option>
<option value="no nodules">no nodule</option>
<option value=""></option>
</select></td>
<td><select name="Speculum Exam" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="no lesions on cervix">no lesions</option>
<option value="no discharge">no disch</option>
</select></td>
<td><select name="Internal Exam" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="uterus not enlarged">ut not large</option>
<option value="normal ad nexa">neg adnexa</option>
</select></td>!;
  }
  $page .=      qq!<td><select name="Extremities Exam" multiple="multiple" default="normal" size="5">
<option value="normal">normal</option>
<option value="no edema">no edema</option>
<option value="no clubbing">no club</option>
<option value="no cyanosis">no cyan</option>
</select></td>
<td><select name="Pulses Exam" multiple default="normal" size="5">
<option value="normal">normal</option>
<option value="normal carotid bilaterally">nl carot</option>
<option value="normal femoral bilaterally">nl fem</option>
<option value="normal brachial bilaterally">nl brach</option>
<option value="normal radial bilaterally">nl rad</option>
<option value="normal dorsalis pedis bilaterally">nl dp</option>
<option value="normal posterior tibial bilaterally">nl pt</option>
</select></td>
<td><select name="Neurologic Exam" multiple default="normal" size="5">
<option value="normal">normal</option>
<option value="canial nerves I - XII intact">CN intact</option>
<option value="sensory and motor nerves intact">SM intact</option>
<option value="cerebelar nerves intact">cere int</option>
<option value="no Babinki">no bab</option>
<option value="deep tendon reflexes bilaterally equal and reactive">DTR's =</option>
</select></td></tr>
<tr><td><input type=text name="Rectal Exam Text" size="20" /></td>!;
  if ($sex eq 'M'){
    $page .=     qq!<td><input type=text name="Prostate Exam Text" size="20" /></td>
<td><input type=text name="TestesPenis Exam Text" size="20" /></td>!;
  }
  if ($sex eq 'F'){
    $page .=     qq!<td><input type=text name="External Female Genital Exam Text" size="20" /></td>
<td><input type=text name="Speculum Exam Text" size="20" /></td>
<td><input type=text name="Internal Exam Text" size="20" /></td>!;
  }
  $page .=           qq!<td><input type=text name="Extremities Exam Text" size="20" /></td>
<td><input type=text name="Pulses Exam Text" size="20" /></td>
<td><input type=text name="Neurologic Exam Text" size="20" /></td></tr>
</table></fieldset></td></tr>
<tr><td colspan="8"  align=TOP><fieldset><label>Data Review</label><table>
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
<input type=text name="Review other" size=20/></td></tr>
<tr><td colspan="1"><b>Medications</b></td></tr>!;
  my ($trade_name, $strength, $unit, $route, $frequency, $c);
  $sql = qq!SELECT prescriptions.id, drug, dosage, unit, route_name, frequency 
            FROM prescriptions LEFT JOIN tblroute ON tblroute.route_code=prescriptions.route 
            WHERE patient_id="$patient_id"!;
  $sth = $dbh->prepare($sql);
  $sth ->execute;
  $sth ->bind_columns(\($id, $trade_name, $strength, $unit, $route, $frequency));
  $c = $sth->rows;
  $page .= qq!<tr><td colspan="7">!;
  while ($sth->fetch){
    $route =~ s/\s{2,200}(\w*)\s{2,200}/$1/;
    $frequency =~ s/\s{2,200}(\w*)\s{2,200}/$1/;
    $page .= qq!$trade_name $strength $unit $route $frequency<br>!;
  }
  substr($page, -4)=qq!</td></tr>!;
  $page .= qq!</table></fieldset></td></tr>
<tr><td colspan="8"><input type='submit' name='SubmitButton' value='Completed Subjective/Objective Component'></td></tr>
</table>!;
  return $page;
}

####################################################################################################
##

sub Insert_SO {
  my (@problem_id, $sql, $sth);
      @problem_id = split(/ /,param("Problem List"));
      
      $sql = qq!INSERT INTO pnotes
(date, pid, user, Chief_complaint, Concerns, Location, Quality, Quantity, Timing, Setting, Aggrevating_relieving, Associated_manifestations, Patient_reaction, !;
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
      if (param("General Exam") || param("General Exam Text")){$sql .= qq!General_exam, !;} 
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
      if (param("Breast Exatm") || param("Breast Exatm Text")){$sql .= qq!Breast_exatm, !;} 
      if (param("Abdomen Exam") || param("Abdomen Exam Text")){$sql .= qq!Abdomen_exam, !;} 
      if (param("Rectal Exam") || param("Rectal Exam Text")){$sql .= qq!Rectal_exam, !;} 
      if (param("Prostate Exam") || param("Prostate Exam Text")){$sql .= qq!Prostate_exam, !;} 
      if (param("Testespenis Exam") || param("Testespenis Exam Text")){$sql .= qq!Testespenis_exam, !;} 
      if (param("External Female Exam") || param("External Female Exam Text")){$sql .= qq!External_female_exam, !;} 
      if (param("Speculum Exam") || param("Speculum Exam Text")){$sql .= qq!Speculum_exam, !;} 
      if (param("Internal Exam") || param("Internal Exam Text")){$sql .= qq!Internal_exam, !;} 
      if (param("Extremities Exam") || param("Extremities Exam Text")){$sql .= qq!Extremities_exam, !;} 
      if (param("Neurologic Exam") || param("Neurologic Exam Text")){$sql .= qq!Neurologic_exam, !;}
      chop $sql; chop $sql;
      $sql .= qq!) VALUES ('!.todays_date().qq!', '!.param('patient_id').qq!', '!.param('User').qq!', '!.param('Problem List').qq!', '!;
      foreach (@problem_id){
	$sql .= param("$_ concerns").qq!\t!;
      }
      chop $sql;
      $sql .=qq!', '!;
      foreach (@problem_id){
	$sql .= param("$_ Location").qq!\t!;
      }
      chop $sql;
      $sql .= qq!', '!;
      foreach (@problem_id){
	$sql .= param("$_ Quality").qq!\t!;
      }
      chop $sql;
      $sql .= qq!', '!;
      foreach (@problem_id){
	$sql .= param("$_ Quantity").qq!\t!;
      }
      chop $sql;
      $sql .= qq!', '!;
      foreach (@problem_id){
	$sql .= param("$_ Timing").qq!\t!;
      }
      chop $sql;
      $sql .= qq!', '!;
      foreach (@problem_id){
	$sql .= param("$_ Setting").qq!\t!;
      }
      chop $sql;
      $sql .= qq!', '!;
      foreach (@problem_id){
	$sql .= param("$_ Aggravating Relieving").qq!\t!;
      }
      chop $sql;
      $sql .= qq!', '!;
      foreach (@problem_id){
	$sql .= param("$_ Associated Manifestations").qq!\t!;
      }
      chop $sql;
      $sql .= qq!', '!;
      foreach (@problem_id){
	$sql .= param("$_ Patient Reaction").qq!\t!;
      }
      chop $sql;
      $sql .= qq!', '!;
      if (param("Pain")){$sql .= param("Pain Scale").qq! out of 10 pain in the !.param("Pain Location").qq!', '!;}
      if (param("General")){foreach (param("General")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Skin")){foreach (param("Skin")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Head")){foreach (param("Head")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Eyes")){foreach (param("Eyes")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Ears")){foreach (param("Ears")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Nose and Sinuses")){foreach (param("Nose and Sinuses")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Mouth and Throat")){foreach (param("Mouth and Throat")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Neck")){foreach (param("Neck")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Breasts")){foreach (param("Breasts")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Respiratory")){foreach (param("Respiratory")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Cardiac")){foreach (param("Cardiac")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("GI")){foreach (param("GI")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("GU")){foreach (param("GU")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Male Genital")){foreach (param("Male Genital")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Female Genital")){foreach (param("Female Genital")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Peripheral Vascular")){foreach (param("Peripheral Vascular")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Neurological")){foreach (param("Neurological")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Musc-Skel")){foreach (param("Musc-Skel")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Endo")){foreach (param("Endo")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Heme")){foreach (param("Heme")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Psych")){foreach (param("Psych")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Other Symptoms")){foreach (param("Other Symptoms")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Nutritional Needs")){foreach (param("Nutritional Needs")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Psychological Needs")){foreach (param("Psychological Needs")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Educational Needs")){foreach (param("Educational Needs")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Blood Pressure")){foreach (param("Blood Pressure")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Heart Rate")){foreach (param("Heart Rate")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Respiratory Rate")){foreach (param("Respiratory Rate")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Temperature")){foreach (param("Temperature")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Blood Glucose")){foreach (param("Blood Glucose")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Height")){foreach (param("Height")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("Weight")){foreach (param("Weight")){$sql .=$_.qq!, !;} substr($sql, -2)= qq!', '!;}
      if (param("General Exam")){foreach (param("General Exam")){$sql .=$_.qq!, !;}substr($sql, -2)= qq!', '!;}
      if (param("General Exam Text")){if (param("General Exam")){substr($sql, -4)= qq!, !.param("General Exam Text").qq!', '!;} else {$sql .= param("General Exam Text").qq!', '!;}}
      if (param("Skin Exam")){foreach (param("Skin Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("Skin Exam Text")){if (param("Skin Exam")){substr($sql, -4)= qq!, !.param("Skin Exam Text").qq!', '!;} else {$sql .= param("Skin Exam Text").qq!', '!;}}
      if (param("Eye Exam")){foreach (param("Eye Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("Eye Exam Text")){if (param("Eye Exam")){substr($sql, -4)= qq!, !.param("Eye Exam Text").qq!', '!;} else {$sql .= param("Eye Exam Text").qq!', '!;}}
      if (param("Ear Exam")){foreach (param("Ear Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("Ear Exam Text")){if (param("Ear Exam")){substr($sql, -4)= qq!, !.param("Ear Exam Text").qq!', '!;} else {$sql .= param("Ear Exam Text").qq!', '!;}}
      if (param("Nose Exam")){foreach (param("Nose Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("Nose Exam Text")){if (param("Nose Exam")){substr($sql, -4)= qq!, !.param("Nose Exam Text").qq!', '!;} else {$sql .= param("Nose Exam Text").qq!', '!;}}
      if (param("Mouth Exam")){foreach (param("Mouth Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("Mouth Exam Text")){if (param("Mouth Exam")){substr($sql, -4)= qq!, !.param("Mouth Exam Text").qq!', '!;} else {$sql .= param("Mouth Exam Text").qq!', '!;}}
      if (param("Neck Exam")){foreach (param("Neck Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("Neck Exam Text")){if (param("Neck Exam")){substr($sql, -4)= qq!, !.param("Neck Exam Text").qq!', '!;} else {$sql .= param("Neck Exam Text").qq!', '!;}}
      if (param("Thyroid Exam")){foreach (param("Thyroid Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("Thyroid Exam Text")){if (param("Thyroid Exam")){substr($sql, -4)= qq!, !.param("Thyroid Exam Text").qq!', '!;} else {$sql .= param("Thyroid Exam Text").qq!', '!;}}
      if (param("Lymph Node Exam")){foreach (param("Lymph Node Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("Lymph Node Exam Text")){if (param("Lymph Node Exam")){substr($sql, -4)= qq!, !.param("Lymph Node Exam Text").qq!', '!;} else {$sql .= param("Lymph Node Exam Text").qq!', '!;}}
      if (param("Chest Exam")){foreach (param("Chest Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("Chest Exam Text")){if (param("Chest Exam")){substr($sql, -4)= qq!, !.param("Chest Exam Text").qq!', '!;} else {$sql .= param("Chest Exam Text").qq!', '!;}}
      if (param("Lungs Exam")){foreach (param("Lungs Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("Lungs Exam Text")){if (param("Lungs Exam")){substr($sql, -4)= qq!, !.param("Lungs Exam Text").qq!', '!;} else {$sql .= param("Lungs Exam Text").qq!', '!;}}
      if (param("Heart Exam")){foreach (param("Heart Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("Heart Exam Text")){if (param("Heart Exam")){substr($sql, -4)= qq!, !.param("Heart Exam Text").qq!', '!;} else {$sql .= param("Heart Exam Text").qq!', '!;}}
      if (param("Breast Exam")){foreach (param("Breast Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("Breast Exam Text")){if (param("Breast Exam")){substr($sql, -4)= qq!, !.param("Breast Exam Text").qq!', '!;} else {$sql .= param("Breast Exam Text").qq!', '!;}}
      if (param("Abdomen Exam")){foreach (param("Abdomen Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("Abdomen Exam Text")){if (param("Abdomen Exam")){substr($sql, -4)= qq!, !.param("Abdomen Exam Text").qq!', '!;} else {$sql .= param("Abdomen Exam Text").qq!', '!;}}
      if (param("Rectal Exam")){foreach (param("Rectal Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("Rectal Exam Text")){if (param("Rectal Exam")){substr($sql, -4)= qq!, !.param("Rectal Exam Text").qq!', '!;} else {$sql .= param("Rectal Exam Text").qq!', '!;}}
      if (param("Prostate Exam")){foreach (param("Prostate Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("Prostate Exam Text")){if (param("Prostate Exam")){substr($sql, -4)= qq!, !.param("Prostate Exam Text").qq!', '!;} else {$sql .= param("Prostate Exam Text").qq!', '!;}}
      if (param("TestesPenis Exam")){foreach (param("TestesPenis Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("TestesPenis Exam Text")){if (param("TestesPenis Exam")){substr($sql, -4)= qq!, !.param("TestesPenis Exam Text").qq!', '!;} else {$sql .= param("TestesPenis Exam Text").qq!', '!;}}
      if (param("External Female Genital Exam")){foreach (param("External Female Genital Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("External Female Exam Text")){if (param("External Female Genital Exam")){substr($sql, -4)= qq!, !.param("External Female Genital Exam Text").qq!', '!;} else {$sql .= param("External Female Genital Exam Text").qq!', '!;}}
      if (param("Speculum Exam")){foreach (param("Speculum Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("Speculum Exam Text")){if (param("Speculum Exam")){substr($sql, -4)= qq!, !.param("Speculum Exam Text").qq!', '!;} else {$sql .= param("Speculum Exam Text").qq!', '!;}}
      if (param("Internal Exam")){foreach (param("Internal Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("Internal Exam Text")){if (param("Internal Exam")){substr($sql, -4)= qq!, !.param("Internal Exam Text").qq!', '!;} else {$sql .= param("Internal Exam Text").qq!', '!;}}
      if (param("Extremities Exam")){foreach (param("Extremities Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("Extremities Exam Text")){if (param("Extremities Exam")){substr($sql, -4)= qq!, !.param("Extremities Exam Text").qq!', '!;} else {$sql .= param("Extremities Exam Text").qq!', '!;}}
      if (param("Pulses Exam")){foreach (param("Pulses Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("Pulses Exam Text")){if (param("Pulses Exam")){substr($sql, -4)= qq!, !.param("Pulses Exam Text").qq!', '!;} else {$sql .= param("Pulses Exam Text").qq!', '!;}}
      if (param("Neurologic Exam")){foreach (param("Neurologic Exam")){$sql .=$_.qq!, !;} substr($sql, -2)=qq!', '!;}
      if (param("Neurologic Exam Text")){if (param("Neurologic Exam")){substr($sql, -4)= qq!, !.param("Neurologic Exam Text").qq!', '!;} else {$sql .= param("Neurologic Exam Text").qq!', '!;}}
      substr($sql, -3)='';
      $sql .= qq!)!;
      $sth = $dbh->prepare($sql);
      $sth->execute;
      ######################################### Insert Past/Social/Family History
      if (param("coffee") || param("alcohol") || param("drug") || param("sleep_patterns") || param("exercise_patterns") || param("std") || param("reproduction") || param("sexual_function") || param("self_breast_exam") || param("self_testicle_exam") || param("seatbelt_use") || param("counseling") || param("hazardous_activities") || param("history_mother") || param("history_father") || param("history_siblings") || param("history_offspring") || param("history_spouse") || param("relatives_cancer") || param("relatives_tuberculosis") || param("relatives_diabetes") || param("relatives_hypertension") || param("relatives_heart_problems") || param("relatives_stroke") || param("relatives_epilepsy") || param("relatives_mental_illness") || param("relatives_suicide")){
	$sql = qq!INSERT INTO history_data (!;
	if (param("coffee")){$sql .= qq!coffee, !;}
	if (param("alcohol")){$sql .= qq!alcohol, !;}
	if (param("drug")){$sql .= qq!drug, !;}
	if (param("sleep_patterns")){$sql .= qq!sleep_patterns, !;}
	if (param("exercise_patterns")){$sql .= qq!exercise_patterns, !;}
	if (param("std")){$sql .= qq!std, !;}
	if (param("reproduction")){$sql .= qq!reproduction, !;}
	if (param("sexual_function")){$sql .= qq!sexual_function, !;}
	if (param("self_breast_exam")){$sql .= qq!self_breast_exam, !;}
	if (param("self_testicle_exam")){$sql .= qq!self_testicle_exam, !;}
	if (param("seatbelt_use")){$sql .= qq!seatbelt_use, !;}
	if (param("counseling")){$sql .= qq!counseling, !;}
	if (param("hazardous_activities")){$sql .= qq!hazardous_activities, !;}
	if (param("history_mother")){$sql .= qq!history_mother, !;}
	if (param("history_father")){$sql .= qq!history_father, !;}
	if (param("history_siblings")){$sql .= qq!history_siblings, !;}
	if (param("history_offspring")){$sql .= qq!history_offspring, !;}
	if (param("history_spouse")){$sql .= qq!history_spouse, !;}
	if (param("relatives_cancer")){$sql .= qq!relatives_cancer, !;}
	if (param("relatives_tuberculosis")){$sql .= qq!relatives_tuberculosis, !;}
	if (param("relatives_diabetes")){$sql .= qq!relatives_diabetes, !;}
	if (param("relatives_hypertension")){$sql .= qq!relatives_hypertension, !;}
	if (param("relatives_heart_problems")){$sql .= qq!relatives_heart_problems, !;}
	if (param("relatives_stroke")){$sql .= qq!relatives_stroke, !;}
	if (param("relatives_epilepsy")){$sql .= qq!relatives_epilepsy, !;}
	if (param("relatives_mental_illness")){$sql .= qq!relatives_mental_illness, !;}
	if (param("relatives_suicide")){$sql .= qq!relatives_suicide, !;}
	substr($sql, -2) = qq!) VALUES ('!;
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
	substr($sql, -4) = qq!)!;
	$sth = $dbh->prepare($sql);
	$sth->execute;
      }
    }

####################################################################################
##  Screening and Prevention

sub Screening_Prevention {
  my ($sex, $DOB) = @_;
  my ($sql, $sth, $prevention);
  my ($title, $lname, $fname, $last_prostate_exam, $last_psa, $last_gynocological_exam, $last_breast_exam, $last_mammogram, $last_sigmoidoscopy_colonoscopy, $last_fecal_occult_blood, $last_ppd, $last_bone_density);
  $DOB =~ s/(\d+)\/(\d+)\/(\d+)/$3-$2-$1/;

  ######################################## Screening
  $sql = "SELECT last_prostate_exam, last_psa, last_gynocological_exam, last_breast_exam, last_mammogram, last_sigmoidoscopy_colonoscopy, last_fecal_occult_blood, last_ppd, last_bone_density 
          FROM history_data 
          WHERE pid='".param('patient_id')."'";
  $sth = $dbh->prepare($sql);
  $sth ->execute;
  $sth ->bind_columns(\$last_prostate_exam, \$last_psa, \$last_gynocological_exam, \$last_breast_exam, \$last_mammogram, \$last_sigmoidoscopy_colonoscopy, \$last_fecal_occult_blood, \$last_ppd, \$last_bone_density);
  $prevention =  qq!<table border='0' width='100%', hspace='0'><tr><b>Screening</b></tr>!;
  $sth->fetch;
  if ($sex =~ /^M/){
    if (todays_date()-$DOB>50){
      if ($last_prostate_exam){$prevention .= qq!<tr align='LEFT'><th width='75%'>Prostate Exam: </th><td>$last_prostate_exam</td></tr>!;}
      else{$prevention .= qq!<tr align='LEFT'><td>Recommend Prostate Exam</td></tr>!;}
      if ($last_psa){$prevention .= qq!<tr align='LEFT'><th width='75%'>PSA: </th><td>$last_psa</td></tr>!;}
      else{$prevention .= qq!<tr align='LEFT'><td>Recomment PSA</td></tr>!;}
      if($last_fecal_occult_blood){$prevention .= qq!<tr align='LEFT'><th width='75%'>Fecal Occult Blood: </th><td>$last_fecal_occult_blood</td></tr>!;}
      else{$prevention .= qq!<tr><td>Recommend Fecal Occult Blood</td></tr>!;}
      if($last_sigmoidoscopy_colonoscopy){$prevention .= qq!<tr align='LEFT'><th width='75%'>Sigmoid/Colonoscopy: </th><td>$last_sigmoidoscopy_colonoscopy</td></tr>!;}
      else{$prevention .= qq!<tr><td>Recommend Sigmoid/Colonoscopy</td></tr>!;}
      if($last_ppd){$prevention .= qq!<tr align='LEFT'><th width='75%'>PPD: </th><td>$last_ppd</td></tr>!;}
      else{$prevention .= qq!<tr><td>Recommend PPD</td></tr>!;}
      if($last_bone_density){$prevention .= qq!<tr align='LEFT'><th width='75%'>Bone Density: </th><td>$last_bone_density</td></tr>!;}
      else{$prevention .= qq!<tr><td>Recommend Bone Density</td></tr>!;}
    }
  }
  elsif ($sex =~/^F/){
    if($last_gynocological_exam){$prevention .= qq!<tr align='LEFT'><th width='75%'>PAP Smear: </th><td>$last_gynocological_exam</td></tr>!;}
    else{$prevention .= qq!<tr><td>Recommend PAP Smear</td></tr>!;}
    if($last_breast_exam){$prevention .= qq!<tr align='LEFT'><th width='75%'>Breast Exam: </th><td>$last_breast_exam</td></tr>!;}
    else{$prevention .= qq!<tr><td>Recommend Breast Exam</td></tr>!;}
    if($last_mammogram){$prevention .= qq!<tr align='LEFT'><th width='75%'>Mammogram: </th><td>$last_mammogram</td></tr>!;}
    else{$prevention .= qq!<tr><td>Recommend Mammogram</td></tr>!;}
    if($last_fecal_occult_blood){$prevention .= qq!<tr align='LEFT'><th width='75%'>Fecal Occult Blood: </th><td>$last_fecal_occult_blood</td></tr>!;}
    else{$prevention .= qq!<tr><td>Recommend Fecal Occult Blood</td></tr>!;}
    if($last_sigmoidoscopy_colonoscopy){$prevention .= qq!<tr align='LEFT'><th width='75%'>Sigmoid/Colonoscopy: </th><td>$last_sigmoidoscopy_colonoscopy</td></tr>!;}
    else{$prevention .= qq!<tr><td>Recommend Sigmoid/Colonoscopy</td></tr>!;}
    if($last_ppd){$prevention .= qq!<tr align='LEFT'><th width='75%'>PPD: </th><td>$last_ppd</td></tr>!;}
    else{$prevention .= qq!<tr><td>Recommend PPD</td></tr>!;}
    if($last_bone_density){$prevention .= qq!<tr align='LEFT'><th width='75%'>Bone Density: </th><td>$last_bone_density</td></tr>!;}
    else{$prevention .= qq!<tr><td>Recommend Bone Density</td></tr>!;}
  }
  else {
    $prevention .= qq!<tr><td>Recommend <b>Please Update Patient Gender</b></td></tr>!;
    if($last_fecal_occult_blood){$prevention .= qq!<tr align='LEFT'><th width='75%'>Fecal Occult Blood: </th><td>$last_fecal_occult_blood</td></tr>!;}
    else{$prevention .= qq!<tr><td>Recommend Fecal Occult Blood</td></tr>!;}
    if($last_sigmoidoscopy_colonoscopy){$prevention .= qq!<tr align='LEFT'><th width='75%'>Sigmoid/Colonoscopy: </th><td>$last_sigmoidoscopy_colonoscopy</td></tr>!;}
    else{$prevention .= qq!<tr><td>Recommend Sigmoid/Colonoscopy</td></tr>!;}
    if($last_ppd){$prevention .= qq!<tr align='LEFT'><th width='75%'>PPD: </th><td>$last_ppd</td></tr>!;}
    else{$prevention .= qq!<tr><td>Recommend PPD</td></tr>!;}
    if($last_bone_density){$prevention .= qq!<tr align='LEFT'><th width='75%'>Bone Density: </th><td>$last_bone_density</td></tr>!;}
    else{$prevention .= qq!<tr><td>Recommend Bone Density</td></tr>!;}
  }
  if ($prevention eq qq!<table border='0' width='100%', hspace='0'><tr><b>Screening</b></tr>!){
    $prevention .=qq!<tr><td>No screening test have been done on $title $fname $lname</td></tr>!;
  }
  
  $prevention .= qq!</table>!;
  return $prevention;
}



#  print header; my ($value, $name);
#  foreach  $name ( param() ) {$value = param($name); print "The value of $name is $value<br>\n";}
#  die; This is the latest copy

