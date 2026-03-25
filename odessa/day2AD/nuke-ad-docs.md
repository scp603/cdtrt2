# nuke-ad.ps1 — Documentation
## AD & Windows Security Neutralization Script

---

## Usage

```powershell
# Deploy all payloads
.\nuke-ad.ps1 -Mode install

# Reverse all changes
.\nuke-ad.ps1 -Mode remove

# Check deployment status
.\nuke-ad.ps1 -Mode status
```

Requires: Administrator privileges, Active Directory PowerShell module, Group Policy module.

---

## Protected Accounts (NEVER touched)

- cyberrange
- ansible
- scoring
- GREYTEAM
- krbtgt
- Guest

---

## Phase 1: Windows Security Controls

| # | Attack | What It Does | Why It Hurts |
|---|--------|-------------|-------------|
| 1a | **Firewall Disable** | Disables Windows Firewall on all profiles (Domain/Public/Private) + sets GPO registry keys to prevent re-enable via `gpupdate` | All inbound/outbound filtering gone; GPO keys mean re-enabling via GUI gets overwritten on next policy refresh |
| 1b | **Defender Kill** | Disables real-time monitoring, behavior monitoring, IOAV, script scanning, cloud submission + registry-level policy disable | No AV scanning; malware/tools run freely; registry keys survive Defender service restarts |
| 1c | **UAC Disable** | Sets EnableLUA=0, ConsentPromptBehaviorAdmin=0, PromptOnSecureDesktop=0 | No elevation prompts; all admin processes run with full tokens silently |
| 1d | **Audit Policy Wipe** | `auditpol /clear /y` — removes all success/failure auditing categories | No security event logging; failed logins, privilege use, object access all invisible |
| 1e | **Event Log Cripple** | Disables + clears Security, System, Application, PowerShell, Sysmon, Defender logs; sets max size to 1MB | Existing forensic evidence destroyed; new events either not logged or rapidly overwritten |
| 1f | **AMSI Disable** | Sets AmsiEnable=0 in registry | PowerShell/VBScript/JScript malware scanning bypassed; obfuscated scripts run undetected |
| 1g | **PowerShell Logging Kill** | Disables Script Block Logging, Module Logging, Transcription via policy keys | No PowerShell audit trail; blue team can't see what commands were run |
| 1h | **LSA Protection Disable** | Sets RunAsPPL=0 | LSASS no longer protected; Mimikatz/credential dumping tools can read memory directly |
| 1i | **Credential Guard Disable** | Sets EnableVirtualizationBasedSecurity=0, LsaCfgFlags=0 | Credentials no longer isolated in VM; extractable from LSASS memory |
| 1j | **Auth Protocol Weakening** | LmCompatibilityLevel=0 (accept LM/NTLM), SMB signing disabled on server+client | NTLM relay attacks possible; credential interception via Responder; pass-the-hash trivial |
| 1k | **WDigest Enable** | UseLogonCredential=1 | Plaintext passwords stored in LSASS memory; Mimikatz `sekurlsa::wdigest` recovers them |

---

## Phase 2: Active Directory Destabilization

| # | Attack | What It Does | Why It's Hard to Fix |
|---|--------|-------------|---------------------|
| 2a | **Password Policy Gut** | MinLength=0, Complexity=off, History=0, Lockout=0, ReversibleEncryption=on, MaxAge=unlimited | Blue team must know original values to restore; reversible encryption means existing password hashes get stored in recoverable form on next change |
| 2b | **Kerberos Pre-Auth Disable** | Sets `DoesNotRequirePreAuth` on all non-protected users | Enables AS-REP Roasting — any attacker can request encrypted TGTs for offline cracking without authentication |
| 2c | **LDAP Signing Disable** | LDAPServerIntegrity=0, ChannelBinding=0 | LDAP relay attacks possible; unsigned LDAP modifications accepted; man-in-the-middle on LDAP traffic |
| 2d | **LDAP SSL Disable** | Global Catalog SSL Port=0 | Secure LDAP queries fall back to plaintext; credential interception on LDAP binds |
| 2e | **Reversible Encryption** | Enables reversible password encryption for all non-protected accounts | Passwords stored in a format that can be decrypted (not just hashed); DCSync extracts plaintext |
| 2f | **Kerberos RC4 Downgrade** | SupportedEncryptionTypes=4 (RC4 only) | Forces weak encryption; RC4 Kerberos tickets are fast to crack offline |
| 2g | **AdminSDHolder Backdoor** | Creates `svc-health-check` DA account, grants it GenericAll on AdminSDHolder | AdminSDHolder propagates every 60 minutes automatically by AD design — even if blue team removes DA membership, it gets re-added. They must find and clean the AdminSDHolder ACL specifically |
| 2h | **Tombstone Reduction** | tombstoneLifetime=2 days (default 180) | Deleted AD objects become unrecoverable after 2 days instead of 6 months; if they delete our accounts, we restore; if we delete theirs, they can't |
| 2i | **Replication Sabotage** | Site link replication interval=7 days, cost=99999 | AD changes (password resets, group modifications) take up to 7 days to propagate between sites; blue team thinks they fixed something but the fix hasn't replicated |
| 2j | **OU Protection Strip** | Removes `ProtectedFromAccidentalDeletion` from all OUs | One mis-click or script error deletes entire OU trees (users, groups, computers, GPO links) — catastrophic and hard to recover without AD Recycle Bin |
| 2k | **Rogue GPO** | Creates "Windows Update Health Policy" GPO linked to domain root with Enforced=Yes | Re-applies firewall disable, Defender disable, weak auth, WDigest enable on every gpupdate cycle. Blue team fixes local settings → next GP refresh undoes them. Named innocuously — may not be spotted during triage |
| 2l | **DNS Forwarder Poison** | Replaces DNS forwarders with 127.0.0.1 and 0.0.0.0 | External DNS resolution fails; domain machines can't reach the internet; Windows Update, CRL checks, cloud services all break |
| 2m | **DNS Scavenging Disable** | Disables automatic DNS record cleanup | Stale/poisoned DNS records persist indefinitely; manual cleanup required |
| 2n | **NTDS Weakening** | Disables strict replication consistency + enables anonymous LDAP (dsHeuristics=0000002) | Anyone can enumerate AD without credentials; replication conflicts resolved leniently (our changes win) |
| 2o | **LLMNR Re-enable** | EnableMulticast=1 | Responder/Inveigh can poison LLMNR queries; credential capture on the network |
| 2p | **Kerberoasting Setup** | Adds fake SPNs to up to 20 non-protected enabled accounts | Those accounts become Kerberoastable — any authenticated user can request TGS tickets and crack passwords offline |
| 2q | **Scheduled Task** | `WindowsUpdateHealthCheck` runs as SYSTEM every 15 min + on boot | Re-disables firewall, re-disables Defender, re-clears audit — even if blue team manually fixes, it reverts in ≤15 minutes |

---

## Why This Is Hard for Blue Team to Fix

### Layered Persistence
The script uses three independent persistence mechanisms that reinforce each other:
1. **Rogue GPO** (Enforced, domain-linked) — re-applies weak settings on gpupdate
2. **Scheduled Task** (SYSTEM, 15-min interval) — re-applies even if GPO is removed
3. **AdminSDHolder** (AD-native, 60-min cycle) — re-grants DA even if removed from group

Blue team must find and disable all three simultaneously, or the remaining mechanisms re-apply.

### Non-Obvious Naming
- GPO: "Windows Update Health Policy" — looks like a legitimate Windows Update GPO
- Scheduled Task: "WindowsUpdateHealthCheck" — looks like Windows maintenance
- Backdoor User: "svc-health-check" — looks like a monitoring service account
- Backup Directory: `%SystemRoot%\Temp\.syshealth` — hidden+system attributes

### Cascading Effects
- DNS forwarder poisoning breaks external resolution → blue team can't easily download tools or look up fixes
- Replication delays mean fixes on one DC don't propagate for days
- Tombstone reduction means recovering accidentally deleted objects has a very short window
- OU protection removal means any cleanup mistake is potentially catastrophic

### What Blue Team Must Do to Fully Recover
1. Find and remove rogue GPO ("Windows Update Health Policy")
2. Find and delete scheduled task ("WindowsUpdateHealthCheck")
3. Clean AdminSDHolder ACL (remove svc-health-check GenericAll ACE)
4. Delete svc-health-check account from Domain Admins and AD
5. Restore password policy (must know original values or have backup)
6. Re-enable Kerberos pre-auth on all affected accounts
7. Remove fake SPNs from all accounts
8. Restore LDAP signing and channel binding
9. Restore Kerberos encryption types
10. Restore DNS forwarders to correct upstream resolvers
11. Restore AD replication intervals on all site links
12. Restore tombstone lifetime
13. Re-enable OU deletion protection
14. Restore dsHeuristics to disable anonymous LDAP
15. Re-enable strict replication consistency
16. Disable LLMNR again
17. Restore all Windows security settings (firewall, Defender, UAC, audit, AMSI, PS logging, LSA, WDigest)
18. Run `gpupdate /force` on ALL domain machines
19. Double-rotate krbtgt if golden tickets were suspected
20. Force password reset on all Kerberoasted/AS-REP-roasted accounts

Missing any single step leaves an attack vector open.

---

## Reversibility

All original settings are backed up to `%SystemRoot%\Temp\.syshealth\` (hidden+system):

| Backup File | Contents |
|------------|---------|
| firewall-backup.wfw | Full firewall export |
| defender-prefs.xml | Defender preference snapshot |
| uac-backup.xml | UAC registry values |
| audit-backup.csv | Full audit policy export |
| password-policy.xml | Domain password policy |
| user-preauth-backup.xml | Per-user pre-auth settings |
| adminsdholder-acl.xml | Original AdminSDHolder ACL |
| tombstone-backup.xml | Original tombstone lifetime |
| sitelinks-backup.xml | Original site link config |
| ou-protection-backup.xml | Per-OU deletion protection state |
| rogue-gpo-id.txt | GUID of rogue GPO (for clean removal) |
| dns-forwarders.xml | Original DNS forwarder list |
| dns-scavenging.xml | Original scavenging config |
| spn-targets.xml | Accounts that received fake SPNs |
| lsa-backup.txt | Original RunAsPPL value |
| ldap-signing.txt | Original LDAP signing value |
| reapply.ps1 | Persistence scheduled task script |

Run `.\nuke-ad.ps1 -Mode remove` to restore everything from these backups.

**IMPORTANT**: If the backup directory is deleted, removal must be done manually using the 20-step checklist above.

---

*Generated by Odessa Red Team — CDTRT2*
