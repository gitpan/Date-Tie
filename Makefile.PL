use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Date::Tie',
    'VERSION_FROM'	=> 'lib/Date/Tie.pm', 
    'PREREQ_PM'		=> { Time::Local => 0, Tie::Hash => 0 }, 
);
