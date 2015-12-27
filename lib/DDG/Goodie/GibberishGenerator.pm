package DDG::Goodie::GibberishGenerator;
# ABSTRACT: generates random gibberish

use strict;
use DDG::Goodie;
use utf8;

use Silly::Werder qw(sentence get_werd);

triggers any => qw(nonsense gibberish);

zci is_cached => 0;
zci answer_type => "gibberish_generator";

my %languages = (
    'english'       => ['English', 'small'],
    'german'        => ['German',  ''],
    'french'        => ['French',  ''],
    'shakespearean' => ['Shakespeare', ''],
    'swedish'       => ['Swedish', ''],
);

sub pluralise {
    my ($amount, $to_pluralise) = @_;
    return $amount == 1 ? $to_pluralise : ($to_pluralise . 's');
}

my $types       = qr/(?<type>word|sentence)/i;
my $modifier_re = qr/(?<modifier>English|German|French|Swedish|Shakespearean)/i;
my $amountre    = qr/(?<amount>\d+)/;
my $nonsense_re = qr/(?:nonsense|gibberish)/i;

my $forms = qr/^(?:
     (((?<amount>\d+)\s)?($types)s?\sof((?!$modifier_re).)*(?<modifier>$modifier_re)?+.*($nonsense_re))
    |((?<amount>\d+)\s(?<modifier>$modifier_re)?\s*($nonsense_re)\s($types)s?)
    )$/xi;


# Generates a string containing all the nonsense words/sentences.
sub generate_werds {
    my ($amount, $modifier, $type) = @_;
    my @modifier_args = @{$languages{$modifier}};

    my $werd = Silly::Werder->new();
    my $werds;
    if ($type eq 'sentence') {
        $werds .= join ' ', map { sentence() } (1..$amount);
    } elsif ($type eq 'word') {
        $werd->set_werds_num($amount, $amount);
        $werd->set_language(@modifier_args);
        $werds = $werd->sentence();
    };
    return $werds;
}

handle query_lc => sub {
    my $query   = $_;
    return unless $query =~ $forms;
    my $amount   = $+{'amount'} // 1;
    my $modifier = $+{'modifier'} // 'english';
    my $type     = $+{'type'};
    my $result = generate_werds($amount, $modifier, $type);
    # Proper-case modifier (english -> English)
    my $fmodifier = $modifier =~ s/^\w/\u$&/r;
    # E.g, "3 words of Swedish gibberish"
    my $formatted_input = "$amount @{[pluralise $amount, $type]} of $fmodifier gibberish";

    return $result, structured_answer => {
        id   => 'gibberishgenerator',
        name => 'Answer',
        data => {
            title    => $result,
            subtitle => $formatted_input,
        },
        templates => {
            group  => 'text',
            moreAt => 0,
        }
    }
};

1;
