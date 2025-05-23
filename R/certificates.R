#' Certificates in Key Vault
#'
#' This class represents the collection of certificates stored in a vault. It provides methods for managing certificates, including creating, importing and deleting certificates, and doing backups and restores. For operations with a specific certificate, see [certificate].
#'
#' @docType class
#'
#' @section Methods:
#' This class provides the following methods:
#' ```
#' create(name, subject, x509=cert_x509_properties(), issuer=cert_issuer_properties(),
#'        key=cert_key_properties(), format=c("pem", "pkcs12"),
#'        expiry_action=cert_expiry_action(),
#'        attributes=vault_object_attrs(),
#'        ..., wait=TRUE)
#' import(name, value, pwd=NULL,
#'        attributes=vault_object_attrs(),
#'        ..., wait=TRUE)
#' get(name)
#' delete(name, confirm=TRUE)
#' list()
#' backup(name)
#' restore(backup)
#' get_contacts()
#' set_contacts(email)
#' add_issuer(issuer, provider, credentials=NULL, details=NULL)
#' remove_issuer(issuer)
#' get_issuer(issuer)
#' list_issuers()
#' ```
#' @section Arguments:
#' - `name`: The name of the certificate.
#' - `subject`: For `create`, The subject or X.500 distinguished name for the certificate.
#' - `x509`: Other X.509 properties for the certificate, such as the domain name(s) and validity period. A convenient way to provide this is via the [cert_x509_properties] helper function.
#' - `issuer`: Issuer properties for the certificate. A convenient way to provide this is via the [cert_issuer_properties] helper function. The default is to specify a self-signed certificate.
#' - `key`: Key properties for the certificate. A convenient way to provide this is via the [cert_key_properties] helper function.
#' - `format`: The format to store the certificate in. Can be either PEM or PFX, aka PKCS#12. This also determines the format in which the certificate will be exported (see [certificate]).
#' - `expiry_action`: What Key Vault should do when the certificate is about to expire. A convenient way to provide this is via the [cert_expiry_action] helper function.
#' - `attributes`: Optional attributes for the secret. A convenient way to provide this is via the [vault_object_attrs] helper function.
#' - `value`: For `import`, the certificate to import. This can be the name of a PFX file, or a raw vector with the contents of the file.
#' - `pwd`: For `import`, the password if the imported certificate is password-protected.
#' - `...`: For `create` and `import`, other named arguments which will be treated as tags.
#' - `wait`: For `create` and `import`, whether to wait until the certificate has been created before returning. If FALSE, you can check on the status of the certificate via the returned object's `sync` method.
#' - `backup`: For `restore`, a string representing the backup blob for a key.
#' - `email`: For `set_contacts`, the email addresses of the contacts.
#' - `issuer`: For the issuer methods, the name by which to refer to an issuer.
#' - `provider`: For `add_issuer`, the provider name as a string.
#' - `credentials`: For `add_issuer`, the credentials for the issuer, if required. Should be a list containing the components `account_id` and `password`.
#' - `details`: For `add_issuer`, the organisation details, if required. See the [Azure docs](https://learn.microsoft.com/en-us/rest/api/keyvault/setcertificateissuer/setcertificateissuer#administratordetails) for more information.
#'
#' @section Value:
#' For `get`, `create` and `import`, an object of class `stored_certificate`, representing the certificate itself.
#'
#' For `list`, a vector of key names.
#'
#' For `add_issuer` and `get_issuer`, an object representing an issuer. For `list_issuers`, a vector of issuer names.
#'
#' For `backup`, a string representing the backup blob for a certificate. If the certificate has multiple versions, the blob will contain all versions.
#'
#' @seealso
#' [certificate], [cert_key_properties], [cert_x509_properties], [cert_issuer_properties], [vault_object_attrs]
#'
#' [Azure Key Vault documentation](https://learn.microsoft.com/en-us/azure/key-vault/),
#' [Azure Key Vault API reference](https://learn.microsoft.com/en-us/rest/api/keyvault)
#'
#' @examples
#' \dontrun{
#'
#' vault <- key_vault("mykeyvault")
#'
#' vault$certificates$create("mynewcert", "CN=mydomain.com")
#' vault$certificates$list()
#' vault$certificates$get("mynewcert")
#'
#' # specifying some domain names
#' vault$certificates$create("mynewcert", "CN=mydomain.com",
#'     x509=cert_x509_properties(dns_names=c("mydomain.com", "otherdomain.com")))
#'
#' # specifying a validity period of 2 years (24 months)
#' vault$certificates$create("mynewcert", "CN=mydomain.com",
#'     x509=cert_x509_properties(validity_months=24))
#'
#' # setting management tags
#' vault$certificates$create("mynewcert", "CN=mydomain.com", tag1="a value", othertag="another value")
#'
#' # importing a cert from a PFX file
#' vault$certificates$import("importedcert", "mycert.pfx")
#'
#' # backup and restore a cert
#' bak <- vault$certificates$backup("mynewcert")
#' vault$certificates$delete("mynewcert", confirm=FALSE)
#' vault$certificates$restore(bak)
#'
#' # set a contact
#' vault$certificates$set_contacts("username@mydomain.com")
#' vault$certificates$get_contacts()
#'
#' # add an issuer and then obtain a cert
#' # this can take a long time, so set wait=FALSE to return immediately
#' vault$certificates$add_issuer("newissuer", provider="OneCert")
#' vault$certificates$create("issuedcert", "CN=mydomain.com",
#'     issuer=cert_issuer_properties("newissuer"),
#'     wait=FALSE)
#'
#' }
#' @name certificates
#' @aliases certificates certs
#' @rdname certificates
NULL

vault_certificates <- R6::R6Class("vault_certificates",

public=list(

    token=NULL,
    url=NULL,

    initialize=function(token, url)
    {
        self$token <- token
        self$url <- url
    },

    create=function(name, subject, x509=cert_x509_properties(), issuer=cert_issuer_properties(),
                    key=cert_key_properties(),
                    format=c("pem", "pfx"),
                    expiry_action=cert_expiry_action(),
                    attributes=vault_object_attrs(),
                    ..., wait=TRUE)
    {
        format <- if(match.arg(format) == "pem")
            "application/x-pem-file"
        else "application/x-pkcs12"

        policy <- list(
            issuer=issuer,
            key_props=key,
            secret_props=list(contentType=format),
            x509_props=c(subject=subject, x509),
            lifetime_actions=expiry_action,
            attributes=attributes
        )

        body <- list(policy=policy, attributes=attributes, tags=list(...))

        op <- construct_path(name, "create")
        self$do_operation(op, body=body, encode="json", http_verb="POST")
        cert <- self$get(name)

        if(!wait)
            message("Certificate creation started. Call the sync() method to update status.")
        else while(is.null(cert$cer))
        {
            Sys.sleep(5)
            cert <- self$get(name)
        }
        cert
    },

    get=function(name, version=NULL)
    {
        op <- construct_path(name, version)
        stored_cert$new(self$token, self$url, name, version, self$do_operation(op))
    },

    delete=function(name, confirm=TRUE)
    {
        if(delete_confirmed(confirm, name, "certificate"))
            invisible(self$do_operation(name, http_verb="DELETE"))
    },

    list=function()
    {
        sapply(get_vault_paged_list(self$do_operation(), self$token),
            function(props) basename(props$id))
    },

    backup=function(name)
    {
        self$do_operation(construct_path(name, "backup"), http_verb="POST")$value
    },

    restore=function(name, backup)
    {
        stopifnot(is.character(backup))
        self$do_operation("restore", body=list(value=backup), encode="json", http_verb="POST")
    },

    import=function(name, value, pwd=NULL,
                    attributes=vault_object_attrs(),
                    ..., wait=TRUE)
    {
        if(is.character(value) && length(value) == 1 && file.exists(value))
            value <- readBin(value, "raw", file.info(value)$size)

        body <- list(value=value, pwd=pwd, attributes=attributes, tags=list(...))

        self$do_operation(construct_path(name, "import"), body=body, encode="json", http_verb="POST")
        cert <- self$get(name)

        if(!wait)
            message("Certificate creation started. Call the sync() method to update status.")
        else while(is.null(cert$cer))
        {
            Sys.sleep(5)
            cert <- self$get(name)
        }
        cert
    },

    get_contacts=function()
    {
        self$do_operation("contacts")
    },

    set_contacts=function(email)
    {
        df <- data.frame(email=email, stringsAsFactors=FALSE)
        self$do_operation("contacts", body=list(contacts=df), encode="json", http_verb="PUT")
    },

    delete_contacts=function()
    {
        invisible(self$do_operation("contacts", http_verb="DELETE"))
    },

    add_issuer=function(issuer, provider, credentials=NULL, details=NULL)
    {
        op <- construct_path("issuers", issuer)
        body <- list(provider=provider, credentials=credentials, org_details=details)
        self$do_operation(op, body=body, encode="json", http_verb="PUT")
    },

    get_issuer=function(issuer)
    {
        op <- construct_path("issuers", issuer)
        self$do_operation(op)
    },

    remove_issuer=function(issuer)
    {
        op <- construct_path("issuers", issuer)
        invisible(self$do_operation(op, http_verb="DELETE"))
    },

    list_issuers=function()
    {
        sapply(self$do_operation("issuers")$value, function(x) basename(x$id))
    },

    do_operation=function(op="", ..., options=list())
    {
        url <- self$url
        url$path <- construct_path("certificates", op)
        url$query <- options
        call_vault_url(self$token, url, ...)
    },

    print=function(...)
    {
        url <- self$url
        url$path <- "certificates"
        cat("<key vault endpoint '", httr::build_url(url), "'>\n", sep="")
        invisible(self)
    }
))
