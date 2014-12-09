#!/usr/bin/perl

#print "<html><head><title>hi</title></head><body><h1>yo</h1></body></html>";
## Syntax  perlldap1.pl host searchbase searchstring
$numArgs = $#ARGV + 1;
#if ($numArgs lt 3){
#die "not enough args";
#}

if (length ($ENV{'QUERY_STRING'}) > 0){
      $buffer = $ENV{'QUERY_STRING'};
      @pairs = split(/&/, $buffer);
      foreach $pair (@pairs){
           ($name, $value) = split(/=/, $pair);
           $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
           $in{$name} = $value; 
      }
 }

$ldapserver = $in{'ldapserver'};
$searchbaseQS = $in{'searchbase'};
$searchbase = "ou=" . $searchbaseQS . ",o=yourdomain.com,o=cp";
$searchfilter = $in{'searchfilter'};
$seckey = $in{'seckey'};
#$ldapserver = $ARGV[0];
#$searchbase = $ARGV[1];
#$searchfilter = $ARGV[2];

use Net::LDAP;
$ldap = Net::LDAP->new("$ldapserver") or die "hsit $@";
$mesg = $ldap->bind("cn=username", 
		     password=>"password",
		     version=>3);
		
#print("$mesg\n");

print "Content-Type: text/xml\n\n";


sub LDAPsearch
        {
          my ($ldap,$searchString,$attrs,$base) = @_ ;
          # if they don't pass a base... set it for them
          if(!$base ) { $base = "ou=Department,o=yourdomain.com,o=cp"; }
          if(!$searchString) { $searchString = "cn=*"; }
          # if they don't pass an array of attributes...
          # set up something for them
          if (!$attrs ) { $attrs = ['cn','pdsLoginId' ]; }
          my $result = $ldap->search (
                base    => "$base",
                scope   => "sub",
                filter  => "$searchString",
                attrs   =>  $attrs
                );
        }
    my @Attrs = ();             # request all available attributes
                                # to be returned.
    my $result = LDAPsearch($ldap,$searchfilter,\@Attrs,$searchbase);

#------------
     #
     # Accessing the data as if in a structure
     #  i.e. Using the "as_struct"  method
     #
        my $href = $result->as_struct;
        # get an array of the DN names
        my @arrayOfDNs  = keys %$href ;        # use DN hashes
        # process each DN using it as a key
        print "<?xml version='1.0'?>\n";
        print "\n";
        print "<searchroot>\n";
        foreach (@arrayOfDNs) {
           print "\t<resultchild>\n";
           print "\t\t<dn>", $_,"</dn>\n";
           my $valref = $$href{$_};
           # get an array of the attribute names
           # passed for this one DN.
           my @arrayOfAttrs = sort keys %$valref; #use Attr hashes
           my $attrName;        
           foreach $attrName (@arrayOfAttrs) {
             # skip any binary data: yuck!
             next if ( $attrName =~ /;binary$/ );
             # get the attribute value (pointer) using the
             # attribute name as the hash
             my $attrVal =  @$valref{$attrName} ;
		$attrString = "@$attrVal";
		$attrString =~ s/&/&amp\;/g;
                print "\t\t<$attrName>$attrString</$attrName> \n";
		#$attrVal =~ s/&/&amp\;/g;
                ##print "\t\t<$attrName>@$attrVal</$attrName> \n";
             }
           print "\t</resultchild>\n";
           #print "\n";
           # End of that DN
         }
         print "</searchroot>\n";
      #
      #  end of as_struct method
      #
      #--------
      #------------
      #
      # handle each of the results independently
      # ... i.e. using the walk through method
      #
       # my @entries = $result->entries;
        #my $entr ;
        #foreach $entr ( @entries )
         #  {
          #  print "DN: ",$entr->dn,"\n";
            ##my @attrs = sort $entr->attributes;
           # my $attr;
           #foreach $attr ( sort $entr->attributes ){
            #    #skip binary we can't handle
              #  next if ( $attr =~ /;binary$/ );
             #  print "  $attr : ",$entr->get_value($attr),"\n";
              #  }
            ##print "@attrs\n";
             #   print "#-------------------------------\n";
           #}
      #
      # end of walk through method
      #------------


$ldap->unbind;

exit (0);

