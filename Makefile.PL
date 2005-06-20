use 5.006;
use inc::Module::Install;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $version = '0.02';
my $name    = 'NCGI';
my $fname   = "NCGI-$version";

my $prereqs = {
    'Class::Singleton' => 0,
    'XML::API'         => 0.05,
};

sub MY::postamble { "

changes:
	echo 'Changelog for $name' > $$
	echo '' >> $$
	-darcs changes >> $$ && mv $$ Changes
	rm -f $$

deb: changes
	(head -1 debian/changelog | grep $version) || exit 1
	rm -f $fname.tar.gz
	-chmod 755 debian/rules
	\$(MAKE) dist
	tar zxvf $fname.tar.gz
	cd $fname && dpkg-buildpackage -b -rfakeroot -tc
	rm -rf $fname

tgz:
	rm -f $name.tgz
	ln -s $fname.tar.gz $name.tgz
";
}

WriteMakefile(
    NAME              => $name,
    VERSION           => $version,
    PREREQ_PM         => $prereqs,
    ABSTRACT          => 'A New CGI Module',
    AUTHOR            => 'Mark Lawrence <nomad@null.net>',
#    EXE_FILES         => ['bin/parselog.cgi'],
);



sub get_cgi_dir {

    my $dir = $ENV{'CGIBINDIR'} || "/usr/lib/cgi-bin";

    if ( lc((uname)[0]) eq "freebsd" and -d "/usr/local/www/cgi-bin") {
        $dir = "/usr/local/www/cgi-bin";
    }
    elsif ( lc((uname)[0]) eq "darwin" and -d "/Library/WebServer/CGI-Executables") {
        $dir = "/Library/WebServer/CGI-Executables";
    }
    elsif (-d "/usr/local/apache/cgi-bin") {
        $dir = "/usr/local/apache/cgi-bin";
    }

    return $dir;
}

sub get_cgi_user {

    my $user = 'www-data.www-data';
    return $user;

    if ( lc((uname)[0]) eq "freebsd" and -d "/usr/local/www/cgi-bin") {
        $dir = "/usr/local/www/cgi-bin";
    }
    elsif ( lc((uname)[0]) eq "darwin" and -d "/Library/WebServer/CGI-Executables") {
        $dir = "/Library/WebServer/CGI-Executables";
    }
    elsif (-d "/usr/local/apache/cgi-bin") {
        $dir = "/usr/local/apache/cgi-bin";
    }

    return $dir;
}

