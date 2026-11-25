#!/usr/bin/env bash
# =====================================================================
#   Christmas & Birthday Terminal Gift
#   실행:  curl -fsSL https://raw.githubusercontent.com/<아이디>/<저장소>/main/gift.sh | bash
#   (macOS 기본 bash + perl 만 사용, 설치할 것 없음)
# =====================================================================

main() {

# ======================= ✏️  여기만 수정하세요 =======================
TO_NAME="All Given"                           # 편지 맨 위  "To. ___"
FROM_NAME="NIW"                          # 편지 맨 아래 "From. ___"
INTRO_TEXT="To. You"                    # 첫 화면 큰 글씨 (영문·숫자·기호만)
ITEM1_NAME="DDR2 & DDR3 RAM Keyring"    # 첫 번째 선물 이름
ITEM2_NAME="Snack"                      # 두 번째 선물 이름
FINAL_TITLE="RECEIVE GIFT FROM SENDER"  # 마지막 화면 제목
GIFT_CODE="PTCS-RTC2-MVME-3MTP"         # 마지막 화면 16자리 코드

# 편지 내용: 아래 두 줄(LETTER_END) 사이에 자유롭게 쓰면 돼요. 줄바꿈 그대로 나와요.
IFS= read -r -d '' LETTER_TEXT <<'LETTER_END'
정말 존경하고 사랑하는 다다다다다다다다다다준!! 생일 추카해ㅐㅐ~~~~

작년엔 미쳐 챙겨주진 못 했지만,
올해는 그래도 꼭 챙기기 위해 소박하지만^^ 이딴 걸(?) 준비해봣써!
마음에 안 들 수 있겠지만, 그냥 재롱이다 하고 봐줘. :)

벌써 한 해가 다 지나가고 12월이 되었네.
돌아보면서 내가 난리 쌩쇼 쳐가는 거도 봐주느라 고생했고, 고마웠어..(?)

오늘 하루만큼은 너가 주인공이고, 행복한 시간 보냈으면 좋겟써.

너의 남은 2026년도 잘 끝나기를 응원하고, 할망구랑도 100일 이어지기를 바랄게.
다시 한번 생일 정말 축하해! 안농
LETTER_END
# =====================================================================

  if ! command -v perl >/dev/null 2>&1; then
    echo "perl 이 필요해요. (macOS 기본 탑재)"; return 1
  fi
  if ! { : </dev/tty; } 2>/dev/null; then
    echo "Run this script on macOS Terminal"; return 1
  fi

  export GIFT_TO="$TO_NAME" GIFT_FROM="$FROM_NAME" GIFT_INTRO="$INTRO_TEXT" \
         GIFT_ITEM1="$ITEM1_NAME" GIFT_ITEM2="$ITEM2_NAME" \
         GIFT_TITLE="$FINAL_TITLE" GIFT_CODE="$GIFT_CODE" GIFT_LETTER="$LETTER_TEXT"

  perl - <<'__PERL__'
use strict; use warnings; use utf8;
use Time::HiRes qw(time sleep);
use Encode qw(decode);
use POSIX ();
use List::Util qw(shuffle);

$SIG{__WARN__} = sub { if ($ENV{GIFT_DEBUG}) { open my $f, '>>', '/tmp/gift_warn.log'; print $f @_ } };
binmode STDOUT, ':encoding(UTF-8)';
$| = 1;
srand();

my $PI = 4 * atan2(1, 1); my $TAU = 2 * $PI;
sub E { my ($k, $d) = @_; my $v = $ENV{$k}; return $d unless defined $v && length $v; return decode('UTF-8', $v) }
my $TO     = E('GIFT_TO', 'You');
my $FROM   = E('GIFT_FROM', 'Me');
my $INTRO  = E('GIFT_INTRO', 'To. You');
my $ITEM1  = E('GIFT_ITEM1', 'Unknown');
my $ITEM2  = E('GIFT_ITEM2', 'Unknown');
my $TITLE  = E('GIFT_TITLE', 'RECEIVE GIFT FROM SENDER');
my $CODE   = E('GIFT_CODE', '0000-0000-0000-0000');
my $LETTER = E('GIFT_LETTER', '');
$LETTER =~ s/\r//g; $LETTER =~ s/\s+\z//; $LETTER =~ s/\t/    /g;
$LETTER =~ s/[\x{FE00}-\x{FE0F}\x{200B}-\x{200D}]//g;

# ------------------------------------------------------------------ terminal
open(my $TTY, '<', '/dev/tty') or die "Run this script on macOS Terminal\n";
my $STTY = `stty -g < /dev/tty 2>/dev/null`; chomp $STTY;
system("stty -icanon -echo min 0 time 0 < /dev/tty 2>/dev/null");

# ------------------------------------------------------------------ haptics (Force Touch trackpad, best effort)
my $HAP; my $HAP_PID;
if ($^O eq 'darwin' && !$ENV{GIFT_NO_HAPTIC} && -x '/usr/bin/osascript') {
  my $js = q{ObjC.import('AppKit');var fh=$.NSFileHandle.fileHandleWithStandardInput;var p=$.NSHapticFeedbackManager.defaultPerformer;while(true){var d=fh.availableData;if(d.length==0)break;var s=$.NSString.alloc.initWithDataEncoding(d,4).js;for(var i=0;i<s.length;i++){var c=s.charCodeAt(i)-48;if(c>=0&&c<=2){p.performFeedbackPatternPerformanceTime(c,1);}}}};
  if (pipe(my $r, my $w)) {
    my $pid = fork();
    if (defined $pid && $pid == 0) {
      close $w; open(STDIN, '<&', $r); open(STDOUT, '>', '/dev/null'); open(STDERR, '>', '/dev/null');
      exec('/usr/bin/osascript', '-l', 'JavaScript', '-e', $js); POSIX::_exit(0);
    }
    if ($pid) { close $r; $HAP = $w; $HAP_PID = $pid; my $o = select($HAP); $| = 1; select($o); }
  }
}
$SIG{PIPE} = 'IGNORE';
sub haptic { return unless $HAP; my $p = shift; $p = 0 unless defined $p; print $HAP $p; }

my $DONE = 0;
sub restore {
  return if $DONE++;
  print "\e[0m\e[?25h\e[?1049l";
  system("stty '$STTY' < /dev/tty 2>/dev/null") if $STTY;
  if ($HAP) { close $HAP; kill 'TERM', $HAP_PID if $HAP_PID; }
}
$SIG{INT} = $SIG{TERM} = $SIG{HUP} = sub { restore(); print "\n"; exit 0 };
END { restore() }

print "\e[?1049h\e[?25l\e[2J";

# ------------------------------------------------------------------ screen buffer
my ($W, $H, $N) = (80, 24, 1920);
sub get_size {
  my $s = `stty size < /dev/tty 2>/dev/null`;
  if ($s && $s =~ /(\d+)\s+(\d+)/ && $1 > 0 && $2 > 0) { ($H, $W) = ($1, $2) }
  $N = $W * $H;
}
my $RESIZED = 1; $SIG{WINCH} = sub { $RESIZED = 1 };

my (@C, @A, @PC, @PA, @RND);
my $FULL = 1;
my $BG = 256;
sub at { my ($fg, $bg, $b) = @_; $fg = 256 unless defined $fg; $bg = 256 unless defined $bg; return $fg | ($bg << 9) | (($b ? 1 : 0) << 18) }
sub fa { at($_[0], $BG, $_[1]) }
sub clear_buf { my $a = at(256, $BG, 0); @C = (' ') x $N; @A = ($a) x $N; }

sub iswide {
  my $o = ord($_[0]);
  return 0 if $o < 0x1100;
  return 1 if $o <= 0x115F || ($o >= 0x2E80 && $o <= 0xA4CF && $o != 0x303F) || ($o >= 0xAC00 && $o <= 0xD7A3)
    || ($o >= 0xF900 && $o <= 0xFAFF) || ($o >= 0xFE30 && $o <= 0xFE4F) || ($o >= 0xFF00 && $o <= 0xFF60)
    || ($o >= 0xFFE0 && $o <= 0xFFE6) || ($o >= 0x1F300 && $o <= 0x1F64F) || ($o >= 0x1F680 && $o <= 0x1F6FF)
    || ($o >= 0x1F900 && $o <= 0x1F9FF) || ($o >= 0x1FA70 && $o <= 0x1FAFF) || ($o >= 0x20000 && $o <= 0x3FFFD);
  return 0;
}
sub cw { iswide($_[0]) ? 2 : 1 }
sub swidth { my $w = 0; $w += cw($_) for split //, $_[0]; $w }

sub put {
  my ($x, $y, $c, $a) = @_;
  return if $x < 0 || $y < 0 || $x >= $W || $y >= $H;
  my $i = $y * $W + $x;
  $C[$i - 1] = ' ' if $C[$i] eq '' && $x > 0;
  $C[$i + 1] = ' ' if $x + 1 < $W && $C[$i + 1] eq '';
  $C[$i] = $c; $A[$i] = $a;
}
sub putw {
  my ($x, $y, $c, $a) = @_;
  return if $x < 0 || $y < 0 || $x + 1 >= $W || $y >= $H;
  my $i = $y * $W + $x;
  $C[$i - 1] = ' ' if $C[$i] eq '' && $x > 0;
  $C[$i + 2] = ' ' if $x + 2 < $W && $C[$i + 2] eq '';
  $C[$i] = $c; $A[$i] = $a; $C[$i + 1] = ''; $A[$i + 1] = $a;
}
sub text {
  my ($x, $y, $s, $a) = @_;
  for my $ch (split //, $s) {
    if (iswide($ch)) { putw($x, $y, $ch, $a); $x += 2 } else { put($x, $y, $ch, $a); $x++ }
  }
  return $x;
}
sub ctext { my ($y, $s, $a) = @_; text(int(($W - swidth($s)) / 2), $y, $s, $a) }

my %SGRC;
sub sgr {
  my $a = shift;
  return $SGRC{$a} //= do {
    my $fg = $a & 511; my $bg = ($a >> 9) & 511; my $b = ($a >> 18) & 1;
    "\e[0" . ($b ? ";1" : "") . ($fg == 256 ? "" : ";38;5;$fg") . ($bg == 256 ? "" : ";48;5;$bg") . "m";
  };
}
sub present {
  my $o = "\e[?2026h"; my $cur = -1; my $la = -1; my $full = $FULL;
  for (my $i = 0; $i < $N; $i++) {
    next if !$full && $C[$i] eq $PC[$i] && $A[$i] == $PA[$i];
    my $s = $i;
    $s-- if $C[$s] eq '' && ($s % $W) && iswide($C[$s - 1]);
    $o .= "\e[" . (int($s / $W) + 1) . ";" . (($s % $W) + 1) . "H" if $s != $cur;
    my $a = $A[$s]; if ($a != $la) { $o .= sgr($a); $la = $a }
    my $c = $C[$s]; my $wd = 1;
    if ($c eq '') { $c = ' ' } elsif (iswide($c)) { $wd = 2 }
    $o .= $c; $cur = $s + $wd; $cur = -1 if $cur % $W == 0;
    $i = $s + $wd - 1;
  }
  $o .= "\e[?2026l";
  print $o;
  @PC = @C; @PA = @A; $FULL = 0;
}

# ------------------------------------------------------------------ input
sub poll_keys {
  my @k; my $buf = '';
  while (1) {
    my $rin = ''; vec($rin, fileno($TTY), 1) = 1;
    my $n = select(my $rout = $rin, undef, undef, 0);
    last unless $n && $n > 0;
    my $got = sysread($TTY, my $b, 256);
    last unless $got;
    $buf .= $b;
  }
  while (length $buf) {
    if ($buf =~ s/^\e\[[0-9;]*([A-D])// || $buf =~ s/^\eO([A-D])//) {
      push @k, { A => 'up', B => 'down', C => 'right', D => 'left' }->{$1};
    } elsif ($buf =~ s/^\e\[[0-9;]*[~a-zA-Z]//) {
    } elsif ($buf =~ s/^\e//) { push @k, 'esc' }
    else {
      my $c = substr($buf, 0, 1, '');
      push @k, $c eq ' ' ? 'space' : ($c eq "\n" || $c eq "\r") ? 'enter' : lc $c;
    }
  }
  return @k;
}

# ------------------------------------------------------------------ frame loop (fixed 60 fps, time based)
my $FPS = 60; my $MINW = 60; my $MINH = 20;
my ($DBG_T, $DBG_F, $DBG_MAX) = (0, 0, 0);
sub run {
  my ($cb) = @_;
  my $t0 = time; my $prev = $t0; my $next = $t0;
  while (1) {
    if ($RESIZED) {
      $RESIZED = 0; get_size(); @PC = (); @PA = (); $FULL = 1; print "\e[0m\e[2J";
      @RND = map { int rand 1_000_000 } 1 .. $N;
    }
    my $now = time; my $dt = $now - $prev; $prev = $now; $dt = 0.1 if $dt > 0.1;
    my @k = poll_keys();
    clear_buf();
    if ($W < $MINW || $H < $MINH) {
      $t0 += $dt;
      ctext(int($H / 2), "전체화면이 권장됩니다.", fa(252, 1));
      present();
    } else {
      my $r = $cb->($now - $t0, $dt, \@k);
      present();
      if ($ENV{GIFT_DEBUG}) { my $ct = time - $now; $DBG_T += $ct; $DBG_F++; $DBG_MAX = $ct if $ct > $DBG_MAX }
      return unless $r;
    }
    $next += 1 / $FPS;
    my $sl = $next - time;
    if ($sl > 0) { sleep($sl) } elsif ($sl < -0.05) { $next = time }
  }
}

# ------------------------------------------------------------------ math helpers
sub clamp { my ($v, $a, $b) = @_; $v < $a ? $a : $v > $b ? $b : $v }
sub smooth { my ($a, $b, $v) = @_; my $x = clamp(($v - $a) / ($b - $a), 0, 1); $x * $x * (3 - 2 * $x) }
sub ease_out { my $x = clamp(shift, 0, 1); 1 - (1 - $x) ** 3 }
sub ease_io { my $x = clamp(shift, 0, 1); $x < 0.5 ? 4 * $x ** 3 : 1 - ((-2 * $x + 2) ** 3) / 2 }
sub ease_back { my $x = clamp(shift, 0, 1); my $c1 = 1.70158; my $c3 = $c1 + 1; 1 + $c3 * ($x - 1) ** 3 + $c1 * ($x - 1) ** 2 }
sub frac { $_[0] - POSIX::floor($_[0]) }
sub fl { POSIX::floor($_[0]) }
sub min { $_[0] < $_[1] ? $_[0] : $_[1] }
sub max { $_[0] > $_[1] ? $_[0] : $_[1] }

sub mat_mul {
  my ($a, $b) = @_; my @r;
  for my $i (0 .. 2) { for my $j (0 .. 2) {
    $r[$i * 3 + $j] = $a->[$i * 3] * $b->[$j] + $a->[$i * 3 + 1] * $b->[3 + $j] + $a->[$i * 3 + 2] * $b->[6 + $j];
  } }
  return \@r;
}
sub rx { my ($c, $s) = (cos $_[0], sin $_[0]); [1, 0, 0, 0, $c, -$s, 0, $s, $c] }
sub ry { my ($c, $s) = (cos $_[0], sin $_[0]); [$c, 0, $s, 0, 1, 0, -$s, 0, $c] }
sub rz { my ($c, $s) = (cos $_[0], sin $_[0]); [$c, -$s, 0, $s, $c, 0, 0, 0, 1] }
sub mv { my ($m, $v) = @_; [ $m->[0]*$v->[0] + $m->[1]*$v->[1] + $m->[2]*$v->[2], $m->[3]*$v->[0] + $m->[4]*$v->[1] + $m->[5]*$v->[2], $m->[6]*$v->[0] + $m->[7]*$v->[1] + $m->[8]*$v->[2] ] }
my @L = do { my @v = (-0.45, 0.7, -0.6); my $n = sqrt($v[0]**2 + $v[1]**2 + $v[2]**2); map { $_ / $n } @v };

# ------------------------------------------------------------------ shading / materials
my @SR    = split //, '.:-=+*#%@';
my @RED   = (52, 88, 124, 160, 196, 203);
my @GOLD  = (94, 136, 178, 220, 221, 229);
my @GLOW  = (178, 220, 227, 228, 229, 230);
my @PCB   = (22, 22, 28, 28, 34, 35);
my @PCBE  = (22, 22, 22, 28, 28, 29);
my @TRACE = (28, 34, 35, 41, 42, 48);
my @CHIP  = (236, 238, 240, 242, 244, 246);
my @CHOC  = (52, 52, 94, 94, 130, 137);
my @SILV  = (240, 243, 246, 249, 252, 255);
my @TREEC = (22, 22, 28, 28, 34, 34, 40, 70, 76, 112);
my @TREECH= split //, '.,:;+=*#%@';
my @BARK  = (52, 52, 94, 94, 130, 136);
sub shade {
  my ($mat, $I, $bold) = @_;
  $I = 0 if $I < 0; $I = 0.999 if $I >= 1;
  return ($SR[int($I * 9)], at($mat->[int($I * @$mat)], $BG, $bold));
}

# ------------------------------------------------------------------ box ray-caster (orthographic)
# world: X right (1 unit = 2 cols), Y up (1 unit = 1 row), Z into screen
sub render_boxes {
  my ($boxes, $acx, $acy, $zb) = @_;
  my ($x0, $x1, $y0, $y1) = (1e9, -1e9, 1e9, -1e9);
  for my $b (@$boxes) {
    my $m = $b->{m}; my ($hx, $hy, $hz) = @{$b->{h}};
    for my $sx (-1, 1) { for my $sy (-1, 1) { for my $sz (-1, 1) {
      my $p = mv($m, [$sx * $hx, $sy * $hy, $sz * $hz]);
      my $col = $acx + ($p->[0] + $b->{c}[0]) * 2; my $row = $acy - ($p->[1] + $b->{c}[1]);
      $x0 = $col if $col < $x0; $x1 = $col if $col > $x1; $y0 = $row if $row < $y0; $y1 = $row if $row > $y1;
    } } }
    $b->{dl} = [$m->[6], $m->[7], $m->[8]];
  }
  $x0 = max(0, int($x0) - 1); $x1 = min($W - 1, int($x1) + 1);
  $y0 = max(0, int($y0) - 1); $y1 = min($H - 1, int($y1) + 1);
  for my $y ($y0 .. $y1) {
    my $Y = $acy - ($y + 0.5);
    for my $x ($x0 .. $x1) {
      my $X = ($x + 0.5 - $acx) / 2;
      my $best = 1e9; my ($hc, $ha);
      for my $b (@$boxes) {
        my ($m, $c, $h, $dl) = @$b{qw(m c h dl)};
        my $dx = $X - $c->[0]; my $dy = $Y - $c->[1]; my $dz = -50 - $c->[2];
        my @o = ($m->[0]*$dx + $m->[3]*$dy + $m->[6]*$dz, $m->[1]*$dx + $m->[4]*$dy + $m->[7]*$dz, $m->[2]*$dx + $m->[5]*$dy + $m->[8]*$dz);
        my ($tn, $tf, $ax, $sg) = (-1e9, 1e9, -1, 0); my $miss = 0;
        for my $i (0 .. 2) {
          my $d = $dl->[$i]; my $hi = $h->[$i];
          if (abs($d) < 1e-9) { if (abs($o[$i]) > $hi) { $miss = 1; last } next }
          my $t1 = (-$hi - $o[$i]) / $d; my $t2 = ($hi - $o[$i]) / $d;
          ($t1, $t2) = ($t2, $t1) if $t1 > $t2;
          if ($t1 > $tn) { $tn = $t1; $ax = $i; $sg = $d > 0 ? -1 : 1 }
          $tf = $t2 if $t2 < $tf;
          if ($tn > $tf) { $miss = 1; last }
        }
        next if $miss || $ax < 0 || $tn >= $best;
        my @p = ($o[0] + $dl->[0]*$tn, $o[1] + $dl->[1]*$tn, $o[2] + $dl->[2]*$tn);
        my $lam = ($m->[$ax]*$L[0] + $m->[3+$ax]*$L[1] + $m->[6+$ax]*$L[2]) * $sg; $lam = 0 if $lam < 0;
        my @r = $b->{tex}->($ax, $sg, @p, $lam, $b);
        next unless @r;
        $best = $tn; ($hc, $ha) = @r;
      }
      next unless defined $hc;
      my $i = $y * $W + $x; $C[$i] = $hc; $A[$i] = $ha;
      $zb->{$i} = $best - 50 if $zb;
    }
  }
}


# text printed on a box face (both sides readable), drawn after the ray-cast with a z-test
sub face_text {
  my ($b, $acx, $acy, $zb, $str, $py, $x0, $x1, $fg) = @_;
  for my $side (-1, 1) {
    next if $b->{m}[8] * $side > -0.2;
    face_text_side($b, $acx, $acy, $zb, $side == 1 ? scalar reverse($str) : $str, $py, $x0, $x1, $fg, $side);
  }
}

# ------------------------------------------------------------------ matrix rain
my @GLY = split //, '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ@#$%&*+=<>?/\\|{}[]~^:;';
my @RAINC = (231, 194, 157, 120, 84, 48, 46, 40, 34, 34, 28, 28, 22, 22);
my @RAIND = (40, 34, 28, 28, 22, 22, 22, 22, 22, 236);
my (@ry, @rs, @rl); my $RW = 0;
sub rain_reset { my ($c, $y) = @_; $ry[$c] = $y; $rs[$c] = 14 + rand(28); $rl[$c] = 6 + int rand(int($H * 0.6) + 1); }
sub rain_init { my ($above) = @_; $RW = $W; for my $c (0 .. $W - 1) { rain_reset($c, $above ? -rand($H * 1.3) - 1 : rand($H)) } }
sub rain_glyph { my ($i, $t) = @_; my $r = $RND[$i]; $GLY[($r + ($r % 3 == 0 ? int($t * 10 + $r % 7) : 0)) % @GLY] }
sub rain_draw {
  my ($t, $dt, $o) = @_;
  rain_init(0) if $RW != $W;
  my $pal = $o->{dim} ? \@RAIND : \@RAINC;
  my @pa = map { at($_, $BG, 0) } @$pal; my $head = at($pal->[0], $BG, 1);
  my $z = $o->{zone}; my $za = $o->{za} || 0; my $zd = at(22, $BG, 0);
  for my $c (0 .. $W - 1) {
    $ry[$c] += $rs[$c] * $dt;
    rain_reset($c, -rand($H * 0.5) - 1) if $ry[$c] - $rl[$c] > $H;
    my $hy = int $ry[$c]; my $len = $rl[$c];
    for my $k (0 .. $len - 1) {
      my $y = $hy - $k; last if $y < 0; next if $y >= $H;
      my $i = $y * $W + $c;
      my $inz = $z && $za > 0 && $c >= $z->[0] && $c <= $z->[2] && $y >= $z->[1] && $y <= $z->[3];
      next if $inz && ($RND[$i] % 1000) / 1000 < $za;
      $C[$i] = rain_glyph($i, $t);
      $A[$i] = $inz ? $zd : $k == 0 ? $head : $pa[min($#pa, 1 + int($k / $len * $#pa))];
    }
  }
}

# wipe: rain front falls from top and clears the previous screen
sub wipe {
  my ($dur, $newbg) = @_;
  my @SC = @PC; my @SA = @PA; my ($sw, $sh) = ($W, $H);
  my @d = map { rand(0.3) } 0 .. $W - 1;
  my @len = map { 4 + int rand(10) } 0 .. $W - 1;
  my $base = ($H + 16) / ($dur - 0.3);
  my @sp = map { $base * (0.85 + rand 0.3) } 0 .. $W - 1;
  $BG = $newbg if defined $newbg;
  haptic(0);
  run(sub {
    my ($t) = @_;
    return 0 if $W != $sw || $H != $sh;
    my @pa = map { at($_, $BG, 0) } @RAINC; my $head = at(231, $BG, 1);
    my $busy = 0;
    for my $x (0 .. $W - 1) {
      for my $y (0 .. $H - 1) {
        my $i = $y * $W + $x;
        my $cx = ($SC[$i] eq '' && $x > 0) ? $x - 1 : $x;
        my $f = ($t - $d[$cx]) * $sp[$cx];
        if ($y > $f) { $C[$i] = $SC[$i]; $A[$i] = $SA[$i]; $busy = 1 }
        elsif ($y > $f - $len[$cx]) {
          my $k = $f - $y; $C[$i] = rain_glyph($i, $t);
          $A[$i] = $k < 1 ? $head : $pa[min($#pa, 1 + int($k / $len[$cx] * $#pa))]; $busy = 1;
        }
      }
    }
    return $busy || $t < 0.3;
  });
}

# ------------------------------------------------------------------ big font (5x7)
my %FONT;
{
  my %src = (
    A=>'.###.|#...#|#...#|#####|#...#|#...#|#...#', B=>'####.|#...#|#...#|####.|#...#|#...#|####.',
    C=>'.####|#....|#....|#....|#....|#....|.####', D=>'####.|#...#|#...#|#...#|#...#|#...#|####.',
    E=>'#####|#....|#....|####.|#....|#....|#####', F=>'#####|#....|#....|####.|#....|#....|#....',
    G=>'.####|#....|#....|#..##|#...#|#...#|.###.', H=>'#...#|#...#|#...#|#####|#...#|#...#|#...#',
    I=>'###|.#.|.#.|.#.|.#.|.#.|###',               J=>'..###|...#.|...#.|...#.|...#.|#..#.|.##..',
    K=>'#...#|#..#.|#.#..|##...|#.#..|#..#.|#...#', L=>'#....|#....|#....|#....|#....|#....|#####',
    M=>'#...#|##.##|#.#.#|#.#.#|#...#|#...#|#...#', N=>'#...#|##..#|#.#.#|#..##|#...#|#...#|#...#',
    O=>'.###.|#...#|#...#|#...#|#...#|#...#|.###.', P=>'####.|#...#|#...#|####.|#....|#....|#....',
    Q=>'.###.|#...#|#...#|#...#|#.#.#|#..#.|.##.#', R=>'####.|#...#|#...#|####.|#.#..|#..#.|#...#',
    S=>'.####|#....|#....|.###.|....#|....#|####.', T=>'#####|..#..|..#..|..#..|..#..|..#..|..#..',
    U=>'#...#|#...#|#...#|#...#|#...#|#...#|.###.', V=>'#...#|#...#|#...#|#...#|#...#|.#.#.|..#..',
    W=>'#...#|#...#|#...#|#.#.#|#.#.#|##.##|#...#', X=>'#...#|#...#|.#.#.|..#..|.#.#.|#...#|#...#',
    Y=>'#...#|#...#|.#.#.|..#..|..#..|..#..|..#..', Z=>'#####|....#|...#.|..#..|.#...|#....|#####',
    a=>'.....|.....|.###.|....#|.####|#...#|.####', b=>'#....|#....|####.|#...#|#...#|#...#|####.',
    c=>'.....|.....|.####|#....|#....|#....|.####', d=>'....#|....#|.####|#...#|#...#|#...#|.####',
    e=>'.....|.....|.###.|#...#|#####|#....|.####', f=>'..##|.#..|####|.#..|.#..|.#..|.#..',
    g=>'.....|.####|#...#|#...#|.####|....#|.###.', h=>'#....|#....|####.|#...#|#...#|#...#|#...#',
    i=>'.#.|...|##.|.#.|.#.|.#.|###',               j=>'..#|...|.##|..#|..#|#.#|.#.',
    k=>'#...|#...|#..#|#.#.|##..|#.#.|#..#',         l=>'##.|.#.|.#.|.#.|.#.|.#.|###',
    m=>'.....|.....|##.#.|#.#.#|#.#.#|#.#.#|#...#', n=>'.....|.....|####.|#...#|#...#|#...#|#...#',
    o=>'.....|.....|.###.|#...#|#...#|#...#|.###.', p=>'.....|####.|#...#|#...#|####.|#....|#....',
    q=>'.....|.####|#...#|#...#|.####|....#|....#', r=>'.....|.....|#.##.|##..#|#....|#....|#....',
    s=>'.....|.....|.####|#....|.###.|....#|####.', t=>'.#..|.#..|####|.#..|.#..|.#..|..##',
    u=>'.....|.....|#...#|#...#|#...#|#...#|.####', v=>'.....|.....|#...#|#...#|#...#|.#.#.|..#..',
    w=>'.....|.....|#...#|#...#|#.#.#|#.#.#|.#.#.', x=>'.....|.....|#...#|.#.#.|..#..|.#.#.|#...#',
    y=>'.....|#...#|#...#|#...#|.####|....#|.###.', z=>'.....|.....|#####|...#.|..#..|.#...|#####',
    0=>'.###.|#...#|#..##|#.#.#|##..#|#...#|.###.', 1=>'..#..|.##..|..#..|..#..|..#..|..#..|.###.',
    2=>'.###.|#...#|....#|...#.|..#..|.#...|#####', 3=>'####.|....#|....#|.###.|....#|....#|####.',
    4=>'...#.|..##.|.#.#.|#..#.|#####|...#.|...#.', 5=>'#####|#....|####.|....#|....#|#...#|.###.',
    6=>'.###.|#....|#....|####.|#...#|#...#|.###.', 7=>'#####|....#|...#.|..#..|.#...|.#...|.#...',
    8=>'.###.|#...#|#...#|.###.|#...#|#...#|.###.', 9=>'.###.|#...#|#...#|.####|....#|....#|.###.',
    '.'=>'..|..|..|..|..|##|##', ','=>'..|..|..|..|.#|.#|#.', '!'=>'##|##|##|##|##|..|##',
    '?'=>'.###.|#...#|....#|...#.|..#..|.....|..#..', "'"=>'##|##|#.|..|..|..|..',
    '-'=>'....|....|....|####|....|....|....', '&'=>'.##..|#..#.|.##..|.#...|#.#.#|#..#.|.##.#',
    ' '=>'...|...|...|...|...|...|...', '<'=>'...#|..#.|.#..|#...|.#..|..#.|...#', '3'=>'####.|....#|....#|.###.|....#|....#|####.',
  );
  for my $k (keys %src) { $FONT{$k} = [split /\|/, $src{$k}] }
}

# ================================================================== SCENE 1 : rain + "To. You"
sub scene_intro {
  $BG = 256; rain_init(1);
  my $T1 = 2.3;
  my @gl = map { $FONT{$_} || $FONT{'?'} } split //, $INTRO;
  my $tw = -1; $tw += length($_->[0]) + 1 for @gl; $tw = 1 if $tw < 1;
  my @px; my $gx = 0;
  for my $g (@gl) {
    my $w = length $g->[0];
    for my $r (0 .. 6) { for my $c (0 .. $w - 1) { push @px, [$gx + $c, $r, rand()] if substr($g->[$r], $c, 1) eq '#' } }
    $gx += $w + 1;
  }
  my $done = $T1 + 1.75; my $hap = 0;
  my @pulse = (22, 28, 34, 40, 46, 82, 46, 40, 34, 28);
  run(sub {
    my ($t, $dt, $k) = @_;
    my $pw = ($tw * 2 + 4 <= $W) ? 2 : 1;
    my $bw = $tw * $pw; my $bx = int(($W - $bw) / 2); my $by = int(($H - 7) / 2) - 2;
    my $za = smooth($T1 - 0.3, $T1 + 0.9, $t);
    rain_draw($t, $dt, { zone => [$bx - 5, $by - 2, $bx + $bw + 5, $by + 12], za => $za });
    my ($sh1, $sh2, $main, $fl) = (at(28, $BG, 0), at(22, $BG, 0), at(231, $BG, 1), at(46, $BG, 1));
    my @show;
    for my $p (@px) {
      my ($x, $y, $r) = @$p; my $rt = $T1 + $x / $tw * 1.1 + $y / 7 * 0.22 + $r * 0.15;
      next if $t < $rt - 0.35;
      push @show, [$bx + $x * $pw, $by + $y, $t >= $rt];
    }
    for my $s (@show) { next unless $s->[2]; for my $d (0 .. $pw - 1) { put($s->[0] + $d + 2, $s->[1] + 1, '█', $sh2); } }
    for my $s (@show) { next unless $s->[2]; for my $d (0 .. $pw - 1) { put($s->[0] + $d + 1, $s->[1] + 1, '█', $sh1); } }
    for my $s (@show) {
      for my $d (0 .. $pw - 1) {
        if ($s->[2]) { put($s->[0] + $d, $s->[1], '█', $main) }
        else { put($s->[0] + $d, $s->[1], $GLY[int rand @GLY], $fl) }
      }
    }
    if ($t > $done - 0.4 && !$hap) { $hap = 1; haptic(1) }
    if ($t > $done) {
      my $a = smooth($done, $done + 0.6, $t);
      my $ci = $a < 1 ? int($a * 4) : int(4 + 2.5 * (1 + sin(($t - $done) * 3.2)));
      ctext($by + 10, "space to continue", at($pulse[clamp($ci, 0, $#pulse)], $BG, 1));
      for (@$k) { if ($_ eq 'space') { haptic(1); return 0 } }
    }
    return 1;
  });
}

# ================================================================== SCENE 2 : snow + rotating 3D tree + gift
sub tree_R {
  my ($v, $Rb) = @_; my ($r, $k, $u) = (0, 0, 0);
  for my $tier ([0, 0.40, 0.0, 0.50], [0.22, 0.70, 0.24, 0.78], [0.48, 1.0, 0.38, 1.0]) {
    my ($a, $b, $r0, $r1) = @$tier; next if $v < $a || $v > $b;
    my $uu = ($v - $a) / ($b - $a); my $rr = ($r0 + ($r1 - $r0) * $uu) * $Rb;
    if ($rr > $r) { $r = $rr; $k = ($r1 - $r0) / ($b - $a); $u = $uu }
  }
  return ($r, $k, $u);
}

sub scene_tree {
  $BG = 256;
  my ($T_GROW0, $T_GROW1) = (1.3, 4.3);
  my ($T_ORN0, $T_ORN1)   = (4.5, 6.3);
  my ($T_LIT0, $T_LIT1)   = (6.5, 8.0);
  my ($T_STAR0, $T_STAR1) = (8.4, 9.5);
  my $T_GIFT  = 11.0; my $T_FALL = 0.55;
  my $T_OPEN  = 12.7;
  my $T_CREAM = 14.3; my $D_CREAM = 0.95;

  my $Hs = $H;
  my $F0 = max(8, $Hs - 4 - 4 - 2);
  my $NORN = clamp(int($F0 * 2.4), 18, 80);
  my @orn = map { { v => 0.1 + rand(0.86), phi => rand($TAU), col => (196, 220, 39, 201, 231, 208, 46)[int rand 7], big => rand() < 0.5 } } 1 .. $NORN;
  my @ord = shuffle(0 .. $#orn);
  for my $n (0 .. $#ord) { $orn[$ord[$n]]{t} = $T_ORN0 + $n / @ord * ($T_ORN1 - $T_ORN0); $orn[$ord[$n]]{h} = $n % 2 == 0 }
  my $NB = clamp(int($F0 * 3.6), 30, 120);
  my @BULBC = (196, 226, 46, 51, 201, 214, 231, 87);
  my @flakes; my $FW = 0;
  my @sparks; my @puffs; my @rise;
  my %fired;
  my $last_rise = 0;

  run(sub {
    my ($t, $dt, $keys) = @_;
    my $groundY = $H - 3; my $baseY = $groundY;
    my $Ht = $baseY - 4; my $trH = max(2, int($Ht * 0.12 + 0.5));
    my $yTop = $baseY - $Ht + 1; my $yBot = $baseY - $trH; my $F = $yBot - $yTop + 1;
    my $Rb = min($F * 0.48, ($W / 2 - 6) / 2);
    my $cx = $W / 2;
    my $rot = $t * 0.85;

    # ---------- falling snow (behind everything)
    if ($FW != $W * 1000 + $H) {
      $FW = $W * 1000 + $H; my $n = int($W * $H / 40);
      @flakes = map { { x => rand($W), y => -rand($H) - 1, s => 1.5 + rand(4.5), a => rand(1.5), ph => rand($TAU) } } 1 .. $n;
    }
    for my $f (@flakes) {
      $f->{y} += $f->{s} * $dt;
      if ($f->{y} > $groundY + 1) { $f->{y} = -1 - rand(3); $f->{x} = rand($W) }
      next if $f->{y} < 0;
      my $x = int($f->{x} + sin($t * 0.8 + $f->{ph}) * $f->{a}); my $y = int $f->{y};
      next if $x < 0 || $x >= $W;
      my $near = $f->{s} > 4.2; my $mid = $f->{s} > 3;
      put($x, $y, $near ? '*' : $mid ? '+' : '.', at($near ? 255 : $mid ? 250 : 244, $BG, 0));
    }

    # ---------- snow ground (light)
    my $ga = smooth(0, 1.2, $t);
    if ($ga > 0) {
      my @gc = (236, 238, 240, 243, 246, 249, 252, 254);
      my $lv = int($ga * $#gc);
      for my $x (0 .. $W - 1) {
        my $hm = $groundY - ((sin($x * 0.09) + 0.6 * sin($x * 0.23 + 1) > 0.75) ? 1 : 0);
        for my $y ($hm .. $H - 1) {
          my $i = $y * $W + $x; my $r = $RND[$i];
          if ($y == $hm) { $C[$i] = ('_', '-', '~', '.')[$r % 4]; $A[$i] = at($gc[$lv], $BG, 0); }
          else { $C[$i] = ('.', ':', "'", '.', ' ', '`', '.', ' ')[$r % 8]; $A[$i] = at($gc[max(0, $lv - 1 - ($r % 2))], $BG, 0); }
        }
      }
    }

    # ---------- tree
    my $g = smooth($T_GROW0, $T_GROW1, $t);
    my $hgt = $g * $Ht;
    if ($g > 0) {
      # trunk
      my $Rt = max(0.9, $Rb * 0.13);
      for my $y ($yBot + 1 .. $baseY) {
        my $hrow = $baseY - $y + 1; next if $hrow > $hgt + 0.5;
        for my $x (int($cx - 2 * $Rt) .. int($cx + 2 * $Rt)) {
          my $X = ($x + 0.5 - $cx) / 2; next if abs($X) >= $Rt;
          my $s = $X / $Rt; my $cth = sqrt(1 - $s * $s);
          my $lam = -0.45 * $s + 0.6 * $cth; $lam = 0 if $lam < 0;
          my $phi = atan2($s, $cth) + $rot;
          my $I = (0.2 + 0.8 * $lam) * (0.8 + 0.2 * sin($phi * 7));
          my ($c, $a) = shade(\@BARK, $I);
          put($x, $y, ('|', '!', '|', '#')[int(frac($phi * 1.1) * 4)], $a);
        }
      }
      # foliage
      my $sparkA = at(157, $BG, 1);
      for my $y ($yTop .. $yBot) {
        my $hrow = $baseY - $y + 1; next if $hrow > $hgt + 0.5;
        my $v = ($y - $yTop + 0.5) / $F;
        my ($R, $kk, $u) = tree_R($v, $Rb);
        my $sc = $g < 1 ? clamp(($hgt - $hrow) / 3 + 0.3, 0, 1) : 1;
        $R *= $sc; next if $R <= 0.05;
        my $kn = $kk * $Rb / $F;
        my $front = $g < 1 && $hgt - $hrow < 1.2;
        for my $x (int($cx - 2 * $R - 1) .. int($cx + 2 * $R + 1)) {
          next if $x < 0 || $x >= $W;
          my $X = ($x + 0.5 - $cx) / 2; next if abs($X) >= $R;
          my $s = $X / $R; my $cth = sqrt(1 - $s * $s);
          my $nn = sqrt(1 + $kn * $kn);
          my $lam = (-0.45 * $s + 0.7 * $kn + 0.6 * $cth) / $nn / 1.05; $lam = 0 if $lam < 0;
          my $phi = atan2($s, $cth) + $rot;
          my $br = sin($phi * 8 + $v * $F * 0.75);
          my $I = (0.12 + 0.88 * $lam) * (0.74 + 0.26 * $br) * (0.75 + 0.25 * $cth);
          $I += 0.12 if $u > 0.9;
          my $i = $y * $W + $x;
          if ($front) { $C[$i] = '*'; $A[$i] = $sparkA; next }
          if ($u > 0.95 && sin($phi * 13) > 0.55) { $C[$i] = '^'; $A[$i] = at(253, $BG, 0); next }
          $I = 0 if $I < 0; $I = 0.999 if $I >= 1;
          my $ix = int($I * 10);
          $C[$i] = $TREECH[$ix]; $A[$i] = at($TREEC[$ix], $BG, 0);
        }
      }
    }

    # ---------- garland (tinsel) + lights
    my $flashall = ($t > $T_STAR1 && $t < $T_STAR1 + 0.25);
    if ($t > $T_LIT0) {
      my $tin = at(178, $BG, 0); my $tin2 = at(136, $BG, 0);
      for my $n (0 .. 359) {
        my $s = $n / 359; next if $t < $T_LIT0 + $s * ($T_LIT1 - $T_LIT0);
        my $v = 0.97 - 0.89 * $s; my $phi = $s * $TAU * 4 + 0.5;
        my ($R) = tree_R($v, $Rb); my $th = $phi - $rot; my $c = cos($th); next if $c < 0.1;
        my $x = int($cx + 2 * $R * sin($th)); my $y = int($yTop + $v * $F);
        put($x, $y, $n % 3 ? '-' : '~', $n % 2 ? $tin : $tin2) if $n % 2 == 0 || $c > 0.5;
      }
    }
    for my $o (@orn) {
      next if $t < $o->{t};
      if (!$o->{f}) { $o->{f} = 1; haptic(0) if $o->{h} }
      my ($R) = tree_R($o->{v}, $Rb); my $th = $o->{phi} - $rot; my $c = cos($th); next if $c < 0.12;
      my $x = int($cx + 2 * $R * sin($th)); my $y = int($yTop + $o->{v} * $F);
      my $age = $t - $o->{t};
      my $ch = $age < 0.07 ? '.' : $age < 0.15 ? 'o' : ($o->{big} && $c > 0.5) ? '@' : ($c > 0.55 ? 'O' : 'o');
      put($x, $y, $ch, at($age < 0.12 ? 231 : $o->{col}, $BG, $c > 0.45));
    }
    if ($t > $T_LIT0) {
      for my $n (0 .. $NB - 1) {
        my $s = $n / ($NB - 1); my $ton = $T_LIT0 + $s * ($T_LIT1 - $T_LIT0); next if $t < $ton;
        my $v = 0.97 - 0.89 * $s; my $phi = $s * $TAU * 4 + 0.5;
        my ($R) = tree_R($v, $Rb); my $th = $phi - $rot; my $c = cos($th); next if $c < 0.1;
        my $x = int($cx + 2 * $R * 1.02 * sin($th)); my $y = int($yTop + $v * $F);
        my $tw = sin($t * 5.5 + $n * 2.1);
        my $col = $BULBC[($n + int($t * 1.6 + $n * 0.37)) % @BULBC];
        if ($t - $ton < 0.15 || $flashall) { put($x, $y, '@', at(231, $BG, 1)); next }
        put($x, $y, $tw > 0.25 ? '*' : '+', at($col, $BG, $tw > -0.3));
      }
    }

    # ---------- star
    if ($t > $T_STAR0) {
      my $p = ($t - $T_STAR0) / ($T_STAR1 - $T_STAR0);
      my $ty = $yTop - 1.6; my $sy = -4;
      my $scy = $p < 1 ? $sy + ($ty - $sy) * ease_back($p) : $ty;
      my $ang = $rot * 1.3 + ($p < 1 ? (1 - $p) ** 2 * 14 : 0);
      my $Ro = 2.3; my $Ri = 1.0; my $ca = cos($ang);
      for my $y (int($scy - $Ro - 1) .. int($scy + $Ro + 1)) {
        next if $y < 0 || $y >= $H;
        for my $x (int($cx - 2 * $Ro - 2) .. int($cx + 2 * $Ro + 2)) {
          next if $x < 0 || $x >= $W;
          my $X = ($x + 0.5 - $cx) / 2; my $Y = $scy - ($y + 0.5) + 0.5;
          if (abs($ca) < 0.12) {
            next unless abs($X) < 0.35 && abs($Y) < $Ro;
            put($x, $y, '|', at(220, $BG, 1)); next;
          }
          my $uu = $X / $ca; my $r = sqrt($uu * $uu + $Y * $Y); next if $r > $Ro;
          my $a = atan2($uu, $Y); my $seg = $TAU / 5;
          my $f = abs(frac($a / $seg + 0.5) - 0.5) * 2;
          my $lim = $Ro - ($Ro - $Ri) * $f; next if $r > $lim;
          my $I = abs($ca) * (0.55 + 0.45 * (1 - $r / $Ro));
          my @sc = (136, 178, 220, 226, 228, 229, 231);
          my $ix = clamp(int($I * @sc), 0, $#sc);
          put($x, $y, ('.', '+', '*', '#', '@', '@', '@')[$ix], at($sc[$ix], $BG, 1));
        }
      }
      if ($p >= 1 && !$fired{star}) {
        $fired{star} = 1; haptic(2);
        for (1 .. 46) {
          my $a = rand($TAU); my $sp = 6 + rand(18);
          push @sparks, { x => $cx, y => $ty, vx => cos($a) * $sp * 2, vy => sin($a) * $sp * 0.9 - 3, life => 0.6 + rand(0.7), age => 0 };
        }
      }
      if ($p >= 1) {
        for (1 .. 2) {
          next if rand() < 0.4;
          my $a = rand($TAU); my $d = 2.8 + rand(2.5);
          put(int($cx + cos($a) * $d * 2), int($ty + sin($a) * $d * 0.9), rand() < 0.5 ? '.' : '+', at(229, $BG, 0));
        }
      }
    }

    # ---------- gift box
    my $S = clamp($F / 14, 0.8, 1.7);
    my ($hx, $hy, $hz) = (2.0 * $S, 1.45 * $S, 2.0 * $S);
    my $wcol = 2 * $hx * 1.45;
    my $gcx = min($cx + 2 * $Rb + 5 + $wcol, $W - $wcol - 2);
    if ($t > $T_GIFT) {
      my $tg = $t - $T_GIFT;
      my $yaw = 0.65 + $tg * 0.55; my $tilt = -0.42;
      my $hl = 0.3 * $hy;
      my $Rg = mat_mul(rx($tilt), ry($yaw));
      # vertical position
      my $sq = 0; my $hop = 0;
      if ($tg > $T_FALL) { my $e = $tg - $T_FALL; $sq = 0.28 * exp(-$e * 10) * cos($e * 18); $hop = $e < 0.38 ? 0.9 * sin($PI * $e / 0.38) : 0 }
      my ($shx, $shy) = ($hx * (1 + $sq * 0.5), $hy * (1 - $sq));
      my $ylow = 1e9;
      for my $sx (-1, 1) { for my $sy (-1, 1) { for my $sz (-1, 1) { my $p = mv($Rg, [$sx * $shx * 1.08, $sy * $shy, $sz * $hz * 1.08]); $ylow = $p->[1] if $p->[1] < $ylow } } }
      my $rest = $groundY + 0.6 + $ylow;
      my $gcy = $tg < $T_FALL ? -8 + ($rest + 8) * ($tg / $T_FALL) ** 2 : $rest - $hop;
      if ($tg >= $T_FALL && !$fired{land}) {
        $fired{land} = 1; haptic(0);
        for (1 .. 18) { my $d = rand() < 0.5 ? -1 : 1; push @puffs, { x => $gcx + $d * $wcol * 0.8, y => $groundY, vx => $d * (5 + rand(14)), vy => -(2 + rand(6)), life => 0.4 + rand(0.4), age => 0 } }
      }
      my $opened = $t > $T_OPEN;
      my $body = { c => mv($Rg, [0, -$hl, 0]), h => [$shx, $shy - $hl, $hz], m => $Rg, tex => \&gift_tex, rw => 0.3 * $hx, inside => $opened, t => $t };
      my @boxes = ($body);
      my ($lc, $lm);
      if (!$opened) {
        $lc = mv($Rg, [0, $shy - $hl, 0]); $lm = $Rg;
      } else {
        my $p = clamp(($t - $T_OPEN) / 1.3, 0, 1);
        my $st = mv($Rg, [0, $shy - $hl, 0]);
        my $side = ($gcx + $shx * 8 < $W) ? 1 : -1;
        my $st = mv($Rg, [0, $shy - $hl, 0]);
        my $e = ease_out($p);
        $lc = [ $st->[0] + $side * $shx * 3.2 * $e, $st->[1] + 2.2 * $S * $e + $H * 0.9 * $p ** 2.2, 0 ];
        $lm = mat_mul(rx($tilt), mat_mul(ry($yaw + $p * 2.2), rz($side * -1.4 * $e)));
        if (!$fired{open}) { $fired{open} = 1; haptic(1) }
      }
      push @boxes, { c => $lc, h => [$shx * 1.08, $hl, $hz * 1.08], m => $lm, tex => \&gift_tex, rw => 0.3 * $hx };
      render_boxes(\@boxes, $gcx, $gcy, undef);
      # bow on lid
      my $top = mv($lm, [0, $hl, 0]);
      my $bx = int($gcx + ($lc->[0] + $top->[0]) * 2); my $by = int($gcy - ($lc->[1] + $top->[1]) - 0.2);
      put($bx - 1, $by, '(', at(220, $BG, 1)); put($bx, $by, '@', at(229, $BG, 1)); put($bx + 1, $by, ')', at(220, $BG, 1));
      # light rising from opened box
      if ($opened && $t < $T_CREAM + 0.4) {
        my $ty = $gcy - ($shy - $hl) - 0.3;
        while ($last_rise < $t) {
          $last_rise += 1 / 70;
          push @rise, { x => $gcx + (rand() - 0.5) * $wcol * 0.9, y => $ty, vx => (rand() - 0.5) * 6, vy => -(5 + rand(11)), life => 0.6 + rand(0.6), age => 0 };
        }
        my $gl = at(229, $BG, 0);
        for my $yy (max(0, int($ty - 7)) .. int($ty)) {
          for my $xx (int($gcx - $wcol * 0.45) .. int($gcx + $wcol * 0.45)) {
            put($xx, $yy, '|', $gl) if ($RND[($yy * $W + $xx) % $N] + int($t * 20)) % 11 == 0;
          }
        }
      } else { $last_rise = $t }
    }

    # ---------- particles
    for my $set ([\@sparks, 18, [231, 229, 228, 226, 220, 214, 208, 130]], [\@puffs, 16, [255, 253, 251, 249, 246, 243]], [\@rise, -1, [231, 230, 229, 228, 227, 226, 220, 178]]) {
      my ($arr, $gr, $cols) = @$set; my @keep;
      for my $p (@$arr) {
        $p->{age} += $dt; next if $p->{age} > $p->{life};
        $p->{vy} += $gr * $dt; $p->{x} += $p->{vx} * $dt; $p->{y} += $p->{vy} * $dt;
        my $f = $p->{age} / $p->{life};
        put(int($p->{x}), int($p->{y}), $f < 0.3 ? '*' : $f < 0.65 ? '+' : '.', at($cols->[int($f * @$cols)], $BG, $f < 0.5));
        push @keep, $p;
      }
      @$arr = @keep;
    }

    # ---------- cream paper reveal from the gift
    if ($t > $T_CREAM) {
      my $p = ease_io(($t - $T_CREAM) / $D_CREAM);
      my $ocx = $gcx; my $ocy = $groundY - 2;
      my $maxr = 0;
      for my $c ([0, 0], [$W, 0], [0, $H], [$W, $H]) { my $d = sqrt((($c->[0] - $ocx) / 2) ** 2 + ($c->[1] - $ocy) ** 2); $maxr = $d if $d > $maxr }
      my $R = $p * ($maxr + 2);
      my $cream = at(230, 230, 0); my $edge = at(229, 230, 1); my $edge2 = at(223, 256, 0);
      for my $y (0 .. $H - 1) {
        my $dy = $y + 0.5 - $ocy;
        for my $x (0 .. $W - 1) {
          my $dx = ($x + 0.5 - $ocx) / 2; my $d = sqrt($dx * $dx + $dy * $dy);
          my $i = $y * $W + $x;
          if ($d < $R) { $C[$i] = ' '; $A[$i] = $cream }
          elsif ($d < $R + 1.3) { $C[$i] = $RND[$i] % 3 ? '.' : '*'; $A[$i] = $edge2 }
        }
      }
      if (!$fired{cream}) { $fired{cream} = 1; haptic(2) }
      return 0 if $p >= 1;
    }
    return 1;
  });
}

sub gift_tex {
  my ($ax, $sg, $px, $py, $pz, $lam, $b) = @_;
  my $I = 0.2 + 0.8 * $lam; my $rw = $b->{rw};
  if ($b->{inside} && $ax == 1 && $sg == 1) {
    my $g = 0.55 + 0.35 * $I + 0.1 * sin($b->{t} * 9 + $px * 2 + $pz * 3);
    return shade(\@GLOW, $g, 1);
  }
  my $rib = $ax == 0 ? abs($pz) < $rw : $ax == 2 ? abs($px) < $rw : (abs($px) < $rw || abs($pz) < $rw);
  return shade($rib ? \@GOLD : \@RED, $I, $rib);
}

# ================================================================== SCENE 3 : letter
sub scene_letter {
  $BG = 230;
  my @logical = (
    { s => "To. $TO", st => 'head' }, { s => '' },
    (map { { s => $_ } } split(/\n/, $LETTER, -1)),
    { s => '' }, { s => "From. $FROM", st => 'sign', al => 'r' },
  );
  my @sched; my $tt = 0.9; my $g = 0;
  for my $ln (@logical) {
    my @ch;
    for my $c (split //, $ln->{s}) {
      push @ch, [$c, $g]; $sched[$g++] = $tt;
      $tt += 1 / 15;
      $tt += 0.32 if $c =~ /[.!?…]/; $tt += 0.14 if $c =~ /[,~]/;
    }
    $ln->{ch} = \@ch;
    $tt += length($ln->{s}) ? 0.38 : 0.22;
    $tt += 0.3 if ($ln->{st} || '') eq 'head';
  }
  my $total = $g; my $n = 0; my $skip = 0; my $lastn = 0; my $done_t;
  my %wcache;
  my $ink = at(236, $BG, 0); my $head = at(124, $BG, 1); my $cur = at(236, $BG, 0);
  my @pulse = (28, 28, 34, 34, 35, 34, 34, 28);

  run(sub {
    my ($t, $dt, $keys) = @_;
    for (@$keys) {
      next unless $_ eq 'space';
      if ($n < $total) { $skip = 1; haptic(0) } elsif (defined $done_t && $t - $done_t > 0.25) { haptic(1); return 0 }
    }
    if ($skip) { $n = $total } else { $n++ while $n < $total && $sched[$n] <= $t }
    if ($n > $lastn) { haptic(0) unless $skip; $lastn = $n }
    $done_t = $t if $n >= $total && !defined $done_t;

    my $PW = min($W - 4, 74); my $fx0 = int(($W - $PW) / 2); my $fx1 = $fx0 + $PW - 1;
    my $tx = $fx0 + 8; my $TW = $PW - 12;
    my $lines = $wcache{$TW} ||= do {
      my @out;
      for my $ln (@logical) { push @out, map { { ch => $_, st => $ln->{st} || '', al => $ln->{al} || '' } } wrap_chars($ln->{ch}, $TW) }
      \@out;
    };
    my $yT = 2; my $yB = $H - 4; my $cap = $yB - $yT + 1;
    my $nl = @$lines;
    my $sp = ($nl * 2 - 1 <= $cap) ? 2 : 1;
    my $capL = $sp == 2 ? int(($cap + 1) / 2) : $cap;

    # paper frame
    my $fa = at(180, $BG, 0);
    put($fx0, 0, '╭', $fa); put($fx1, 0, '╮', $fa); put($fx0, $H - 2, '╰', $fa); put($fx1, $H - 2, '╯', $fa);
    for my $x ($fx0 + 1 .. $fx1 - 1) { put($x, 0, '─', $fa); put($x, $H - 2, '─', $fa) }
    for my $y (1 .. $H - 3) { put($fx0, $y, '│', $fa); put($fx1, $y, '│', $fa); put($fx0 + 5, $y, '│', at(217, $BG, 0)) }
    if ($sp == 2) { my $ra = at(224, $BG, 0); for (my $y = $yT + 1; $y <= $H - 3; $y += 2) { put($_, $y, '─', $ra) for $fx0 + 6 .. $fx1 - 2 } }
    # tiny holly in the corner
    text($fx1 - 6, 1, '*', at(160, $BG, 1)); text($fx1 - 5, 1, '*', at(160, $BG, 1)); text($fx1 - 4, 1, 'v', at(28, $BG, 1));

    # current line
    my $curL = 0;
    for my $li (0 .. $nl - 1) { my $c = $lines->[$li]{ch}; $curL = $li if @$c && $c->[0][1] < $n }
    my $first = max(0, $curL - $capL + 1);
    my ($cx, $cy);
    for my $li ($first .. min($nl - 1, $first + $capL - 1)) {
      my $L = $lines->[$li]; my $y = $yT + ($li - $first) * $sp;
      my $w = 0; $w += cw($_->[0]) for @{$L->{ch}};
      my $x = $L->{al} eq 'r' ? $tx + $TW - $w : $tx;
      my $a = $L->{st} ? $head : $ink;
      for my $c (@{$L->{ch}}) {
        last if $c->[1] >= $n;
        my $ww = cw($c->[0]);
        if ($ww == 2) { putw($x, $y, $c->[0], $a) } else { put($x, $y, $c->[0], $a) }
        $x += $ww; ($cx, $cy) = ($x, $y);
      }
      if (!defined $cx && $li == $curL) { ($cx, $cy) = ($x, $y) }
    }
    if (defined $cx && ($n < $total || int($t * 2.4) % 2 == 0)) { put($cx, $cy, '▌', $cur) }

    if ($n < $total) { ctext($H - 1, "space: 바로 보기", at(187, $BG, 0)) }
    else {
      my $ci = int(4 + 3.5 * sin(($t - $done_t) * 3.2)); $ci = clamp($ci, 0, $#pulse);
      ctext($H - 1, "space to continue", at($pulse[$ci], $BG, 1));
    }
    return 1;
  });
}

sub wrap_chars {
  my ($chars, $tw) = @_;
  my @tok; my @cur;
  for my $c (@$chars) { if ($c->[0] eq ' ') { push @tok, [@cur] if @cur; @cur = (); push @tok, [$c] } else { push @cur, $c } }
  push @tok, [@cur] if @cur;
  my @out; my @line; my $w = 0;
  for my $tk (@tok) {
    my $tw2 = 0; $tw2 += cw($_->[0]) for @$tk;
    if ($tk->[0][0] eq ' ') {
      if ($w + 1 > $tw) { push @out, [@line]; @line = (); $w = 0; next }
      push @line, $tk->[0]; $w++; next;
    }
    if ($w + $tw2 > $tw) {
      if ($tw2 <= $tw) { push @out, [@line] if @line; @line = (); $w = 0 }
      for my $c (@$tk) { my $x = cw($c->[0]); if ($w + $x > $tw) { push @out, [@line]; @line = (); $w = 0 } push @line, $c; $w += $x }
      next;
    }
    push @line, @$tk; $w += $tw2;
  }
  push @out, [@line];
  return @out;
}

# ================================================================== SCENE 4 : gifts (3D RAM keyring / chocolate)
sub ram_tex {
  my ($ax, $sg, $px, $py, $pz, $lam, $b) = @_;
  my ($hx, $hy) = @{$b->{h}}; my $I = 0.22 + 0.78 * $lam;
  my ($hlx, $hly, $hr) = @{$b->{hole}};
  return () if $py < -$hy + $b->{pin} * 1.15 && abs($px - $b->{notch}) < $hy * 0.09;
  return () if ($px - $hlx) ** 2 + ($py - $hly) ** 2 < $hr * $hr;
  return shade(\@PCBE, $I * 0.85) if $ax != 2;
  if ($py < -$hy + $b->{pin}) {
    return frac($px * 3.1) < 0.6 ? shade(\@GOLD, $I, 1) : shade(\@PCB, $I * 0.7);
  }
  # sticker (front only)
  my ($sx0, $sx1, $sy0, $sy1) = ($hx * 0.16, $hx * 0.8, -$hy * 0.28, $hy * 0.55);
  if ($sg == -1 && $px > $sx0 && $px < $sx1 && $py > $sy0 && $py < $sy1) {
    my $u = ($px - $sx0) / ($sx1 - $sx0);
    my @bgc = (247, 250, 252, 254, 255); my $bgc = $bgc[clamp(int($I * @bgc), 0, $#bgc)];
    return (' ', at(236, $bgc, 0));
  }
  # memory chips
  my $u = ($px + $hx * 0.92) / ($hx * 1.84) * 8;
  if ($u >= 0 && $u < 8 && $py > -$hy * 0.45 && $py < $hy * 0.66) {
    my $fu = frac($u);
    if ($fu > 0.1 && $fu < 0.9) {
      return shade(\@SILV, $I * 0.5) if $py < -$hy * 0.38 || $py > $hy * 0.59;
      my @cb = (235, 236, 237, 238, 239, 240); my $cb = $cb[clamp(int($I * @cb), 0, $#cb)];
      return (frac($px * 1.7 + $py * 0.3) < 0.08 ? '.' : ' ', at($cb + 6 > 255 ? 255 : $cb + 6, $cb, 0));
    }
  }
  return shade(\@TRACE, $I) if sin($px * 2.6) * sin($py * 4.3) > 0.88;
  return shade(\@PCB, $I);
}

sub choc_tex {
  my ($ax, $sg, $px, $py, $pz, $lam, $b) = @_;
  my ($hx, $hy) = @{$b->{h}}; my $I = 0.22 + 0.78 * $lam;
  my $xw = -0.08 * $hx; my $fw = 0.12 * $hx;
  if ($px > $xw + $fw) {
    if ($ax == 2) {
      return shade(\@GOLD, $I, 1) if abs($py) > $hy * 0.74 && abs($py) < $hy * 0.84;
    }
    return shade(\@RED, $I);
  }
  if ($px > $xw) {
    my $n = sin($px * 7.3 + $py * 5.1) + sin($py * 9.7 - $px * 3.3);
    return shade(\@GOLD, $I * (0.7 + 0.18 * $n), 1);
  }
  if ($ax == 2) {
    my $a = frac(($px + $hx) / (2 * $hx) * 6); my $bb = frac(($py + $hy) / (2 * $hy) * 3);
    my $J = $I;
    if ($a < 0.08 || $a > 0.92 || $bb < 0.1 || $bb > 0.9) { $J *= 0.4 }
    elsif ($a < 0.22) { $J += 0.22 } elsif ($a > 0.78) { $J -= 0.2 }
    elsif ($bb > 0.75) { $J += 0.18 } elsif ($bb < 0.25) { $J -= 0.18 }
    return shade(\@CHOC, $J);
  }
  return shade(\@CHOC, $I * 0.85);
}

sub sticker_text {   # front face only
  my ($b, $acx, $acy, $zb, $str, $py, $x0, $x1, $fg) = @_;
  return if -$b->{m}[8] > -0.2;
  face_text_side($b, $acx, $acy, $zb, $str, $py, $x0, $x1, $fg, -1);
}
sub face_text_side {
  my ($b, $acx, $acy, $zb, $str, $py, $x0, $x1, $fg, $side) = @_;
  my $m = $b->{m}; my $hz = $b->{h}[2];
  my @ch = split //, $str; my $n = @ch; return unless $n;
  my $fx = abs($m->[0]); return if $fx < 0.55;
  my $need = $n * 0.5 / $fx;                        # exactly one column per letter on screen
  return if $need > ($x1 - $x0) * 1.02;
  my $mid = ($x0 + $x1) / 2; ($x0, $x1) = ($mid - $need / 2, $mid + $need / 2);
  my @pts; my $sx = 0;
  for my $k (0 .. $n - 1) {
    my $px = $x0 + ($x1 - $x0) * ($k + 0.5) / $n;
    my $p = mv($m, [$px, $py, $side * $hz]);
    my $X = $acx + ($p->[0] + $b->{c}[0]) * 2;
    push @pts, [$X, int($acy - ($p->[1] + $b->{c}[1])), $p->[2] + $b->{c}[2]]; $sx += $X;
  }
  my $start = int($sx / $n - $n / 2 + 0.5);
  my $dir = $pts[-1][0] >= $pts[0][0] ? 1 : -1;
  for my $k (0 .. $n - 1) {
    next if $ch[$k] eq ' ';
    my $x = $dir > 0 ? $start + $k : $start + $n - 1 - $k; my $y = $pts[$k][1];
    next if $x < 0 || $y < 0 || $x >= $W || $y >= $H;
    my $i = $y * $W + $x;
    next if defined $zb->{$i} && $pts[$k][2] > $zb->{$i} + 0.4;
    $C[$i] = $ch[$k]; $A[$i] = at($fg, ($A[$i] >> 9) & 511, 1);
  }
}

sub draw_ram {
  my ($t, $acx, $acy, $s) = @_;
  my $hx = clamp(($W - 14) / 4.8, 7, 17); my $hy = $hx * 0.23;
  my $hyMax = ($H - 13) / 2.0; if ($hy > $hyMax) { $hy = max(2.2, $hyMax); $hx = $hy / 0.23 }
  $hx *= $s; $hy *= $s; my $hz = 0.16 * $s;
  my $yaw = $t * 0.85 + 0.35; my $Rg = mat_mul(rx(-0.3), ry($yaw));
  my $P = [-$hx + $hy * 0.4, $hy - $hy * 0.4, 0];
  my $sh = [0, -$hy * 0.25, 0];
  my @boxes;
  for my $st ([0.09, -0.42, 'DDR3', '4GB 1600', -0.12], [-0.13, 0.42, 'DDR2', '2GB 800', 0.05]) {
    my ($roll, $zo, $l1, $l2, $notch) = @$st;
    my $Rz = rz($roll);
    my $cl = mv($Rz, [-$P->[0], -$P->[1], 0]);
    my $asm = [$cl->[0] + $P->[0] + $sh->[0], $cl->[1] + $P->[1] + $sh->[1], $zo];
    push @boxes, { c => mv($Rg, $asm), h => [$hx, $hy, $hz], m => mat_mul($Rg, $Rz), tex => \&ram_tex,
      lab1 => $l1, lab2 => $l2, notch => $notch * $hx, hole => [$P->[0], $P->[1], $hy * 0.15], pin => $hy * 0.28 };
  }
  my %zb; render_boxes(\@boxes, $acx, $acy, \%zb);
  for my $b (@boxes) {
    my ($sx0, $sx1, $sy0, $sy1) = ($hx * 0.16, $hx * 0.8, -$hy * 0.28, $hy * 0.55);
    my $hh = ($sy1 - $sy0);
    if ($hh * abs($b->{m}[4]) >= 1.6) {
      sticker_text($b, $acx, $acy, \%zb, $b->{lab1}, $sy0 + $hh * 0.72, $sx0, $sx1, 124);
      sticker_text($b, $acx, $acy, \%zb, $b->{lab2}, $sy0 + $hh * 0.28, $sx0, $sx1, 236);
    } else {
      sticker_text($b, $acx, $acy, \%zb, "$b->{lab1} $b->{lab2}", $sy0 + $hh * 0.5, $sx0, $sx1, 236);
    }
  }
  # key ring through the holes
  my $rr = $hy * 0.95;
  my $rc = [$P->[0] - $rr * 0.7071 + $sh->[0], $P->[1] + $rr * 0.7071 + $sh->[1], 0];
  my %rz;
  for my $n (0 .. 259) {
    my $ph = $n / 260 * $TAU;
    my @q = ($rc->[0] + $rr * cos($ph) * 0.7071, $rc->[1] - $rr * cos($ph) * 0.7071, $rr * sin($ph));
    my $p = mv($Rg, \@q);
    my $nv = mv($Rg, [cos($ph) * 0.7071, -cos($ph) * 0.7071, sin($ph)]);
    my $x = int($acx + $p->[0] * 2); my $y = int($acy - $p->[1]);
    next if $x < 0 || $y < 0 || $x >= $W || $y >= $H;
    my $i = $y * $W + $x;
    next if defined $zb{$i} && $p->[2] > $zb{$i};
    next if defined $rz{$i} && $p->[2] > $rz{$i};
    $rz{$i} = $p->[2];
    my $lam = $nv->[0] * $L[0] + $nv->[1] * $L[1] + $nv->[2] * $L[2]; $lam = 0 if $lam < 0;
    my $I = 0.25 + 0.75 * $lam;
    $C[$i] = ('.', 'o', 'o', 'O', '0', '@')[clamp(int($I * 6), 0, 5)];
    $A[$i] = at($SILV[clamp(int($I * 6), 0, 5)], $BG, $I > 0.6);
  }
}

sub draw_choc {
  my ($t, $acx, $acy, $s) = @_;
  my $hx = clamp(($W - 14) / 4.6, 7, 16); my $hy = $hx * 0.42;
  my $hyMax = ($H - 12) / 2.4; if ($hy > $hyMax) { $hy = max(3, $hyMax); $hx = min($hx, $hy / 0.36) }
  $hx *= $s; $hy *= $s; my $hz = max(0.35, $hx * 0.045) * $s;
  my $Rg = mat_mul(rx(-0.26), mat_mul(ry($t * 0.75 - 0.5), rz(0.035 * sin($t * 1.3))));
  my $b = { c => [0, 0, 0], h => [$hx, $hy, $hz], m => $Rg, tex => \&choc_tex };
  my %zb; render_boxes([$b], $acx, $acy, \%zb);
  my $x0 = 0.04 * $hx;
  face_text($b, $acx, $acy, \%zb, 'CHOCOLATE', 0, $x0 + 0.3, $hx - 0.3, 229);
}

sub scene_items {
  $BG = 256;
  my $idx = 0; my $from = 0; my $sw = -10; my $dir = 1; my $press = -10;
  my @names = ($ITEM1, $ITEM2);
  my @stars = map { [rand(), rand(), rand($TAU)] } 1 .. 70;
  run(sub {
    my ($t, $dt, $keys) = @_;
    for (@$keys) {
      if (($_ eq 'right' || $_ eq 'left') && $t - $sw > 0.35) {
        $dir = $_ eq 'right' ? 1 : -1; $from = $idx; $idx = ($idx + $dir) % 2; $sw = $t; $press = $t; haptic(1);
      } elsif ($_ eq 'space' && $t > 0.8) { haptic(2); return 0 }
    }
    for my $s (@stars) {
      my $tw = sin($t * 1.7 + $s->[2]); next if $tw < -0.2;
      put(int($s->[0] * $W), int($s->[1] * ($H - 6)), $tw > 0.7 ? '+' : '.', at($tw > 0.7 ? 242 : 238, $BG, 0));
    }
    my $cy = int(($H - 6) / 2) + 1;
    my $enter = ease_back(min(1, $t / 0.7)); $enter = 0.05 if $enter < 0.05;
    my $p = ($t - $sw) / 0.5;
    my @draw = $p < 1 ? ([$from, -$dir * ease_io($p) * $W], [$idx, $dir * (1 - ease_io($p)) * $W]) : ([$idx, 0]);
    for my $d (@draw) {
      my ($id, $off) = @$d;
      if ($id == 0) { draw_ram($t, $W / 2 + $off, $cy, $enter) } else { draw_choc($t, $W / 2 + $off, $cy, $enter) }
    }
    my $show = $p < 1 ? ($p < 0.5 ? $from : $idx) : $idx;
    my $la = $p < 1 ? abs($p - 0.5) * 2 : min(1, $t / 0.6);
    my @lc = (236, 240, 245, 250, 255, 231);
    ctext($H - 5, $names[$show], at($lc[clamp(int($la * $#lc), 0, $#lc)], $BG, 1));
    my $hl = $t - $press < 0.25;
    my $ctr = sprintf("<    %d / 2    >", $idx + 1);
    my $x0 = int(($W - length $ctr) / 2);
    text($x0, $H - 3, $ctr, at(244, $BG, 0));
    put($x0, $H - 3, '<', at(($hl && $dir < 0) ? 46 : 250, $BG, 1));
    put($x0 + length($ctr) - 1, $H - 3, '>', at(($hl && $dir > 0) ? 46 : 250, $BG, 1));
    my $ci = int(2 + 1.6 * sin($t * 3.2)); my @pc = (22, 28, 34, 40, 46);
    ctext($H - 1, "← → 넘기기      space to continue", at($pc[clamp($ci, 0, 4)], $BG, 1));
    return 1;
  });
}

# ================================================================== SCENE 5 : final
sub scene_final {
  $BG = 256; rain_init(1);
  my @title = split //, $TITLE; my @code = split //, $CODE;
  my $hap = 0; my $hap2 = 0;
  my $tdone = 1.6 + @code * 0.06 + 0.2;
  run(sub {
    my ($t, $dt, $keys) = @_;
    my $cy = int($H / 2) - 2;
    my $spaced = ($W >= @title * 2 + 6);
    my $ts = $spaced ? join(' ', @title) : join('', @title);
    my @tc = split //, $ts;
    my $cs = join(' ', @code); my @cc = split //, $cs;
    my $bw = max(scalar(@cc) + 8, 20);
    my $bx0 = int(($W - $bw) / 2);
    rain_draw($t, $dt, { dim => 1, zone => [min($bx0, int(($W - @tc) / 2)) - 4, $cy - 3, max($bx0 + $bw, int(($W + @tc) / 2)) + 4, $cy + 7], za => smooth(0, 0.6, $t) });
    my $tx = int(($W - @tc) / 2);
    for my $i (0 .. $#tc) {
      my $c = $tc[$i]; next if $c eq ' ';
      my $rt = 0.35 + ($spaced ? $i / 2 : $i) * 0.035;
      next if $t < $rt - 0.4;
      if ($t < $rt) { put($tx + $i, $cy, $GLY[int rand @GLY], at(34, $BG, 0)) }
      else { put($tx + $i, $cy, $c, at($t - $rt < 0.08 ? 231 : 46, $BG, 1)) }
    }
    if (!$hap && $t > 0.35 + @title * 0.035) { $hap = 1; haptic(1) }
    if ($t > 1.2) {
      my $ba = at(smooth(1.2, 1.6, $t) > 0.5 ? 34 : 22, $BG, 0);
      put($bx0, $cy + 2, '┌', $ba); put($bx0 + $bw - 1, $cy + 2, '┐', $ba);
      put($bx0, $cy + 4, '└', $ba); put($bx0 + $bw - 1, $cy + 4, '┘', $ba);
      for my $x ($bx0 + 1 .. $bx0 + $bw - 2) { put($x, $cy + 2, '─', $ba); put($x, $cy + 4, '─', $ba) }
      put($bx0, $cy + 3, '│', $ba); put($bx0 + $bw - 1, $cy + 3, '│', $ba);
      my $cx = int(($W - @cc) / 2);
      for my $i (0 .. $#cc) {
        my $c = $cc[$i]; next if $c eq ' ';
        my $rt = 1.6 + int($i / 2) * 0.06;
        next if $t < $rt - 0.5;
        if ($t < $rt) { put($cx + $i, $cy + 3, $GLY[int rand @GLY], at(28, $BG, 0)) }
        else { put($cx + $i, $cy + 3, $c, at($t - $rt < 0.1 ? 157 : 231, $BG, 1)) }
      }
    }
    if (!$hap2 && $t > $tdone) { $hap2 = 1; haptic(2) }
    if ($t > $tdone + 1.5) {
      ctext($H - 2, "press any key to exit", at(240, $BG, 0));
      return 0 if @$keys;
    }
    return 1;
  });
}

# ================================================================== main
my $ok = eval {
  scene_intro();
  wipe(1.1);
  scene_tree();
  scene_letter();
  wipe(1.2, 256);
  scene_items();
  wipe(1.1);
  scene_final();
  1;
};
my $err = $@;
restore();
if (!$ok) { print STDERR "\n오류가 발생했어요: $err\n"; exit 1 }
print "\n  \x{1F384}  Merry Christmas & Happy Birthday, $TO!  \x{1F382}\n\n";
if ($ENV{GIFT_DEBUG} && $DBG_F) {
  open my $f, '>', '/tmp/gift_debug.txt';
  printf $f "frames=%d avg=%.2fms max=%.2fms size=%dx%d\n", $DBG_F, $DBG_T / $DBG_F * 1000, $DBG_MAX * 1000, $W, $H;
}
__PERL__
}

main "$@"
