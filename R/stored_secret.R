#' Stored secret object
#'
#' This class represents a secret stored in a vault.
#'
#' @docType class
#'
#' @section Fields:
#' This class provides the following fields:
#' - `value`: The value of the secret.
#' - `id`: The ID of the secret.
#' - `kid`: If this secret backs a certificate, the ID of the corresponding key.
#' - `managed`: Whether this secret's lifetime is managed by Key Vault. TRUE if the secret backs a certificate.
#' - `contentType`: The content type of the secret.
#'
#' @section Methods:
#' This class provides the following methods:
#' ```
#' update_attributes(attributes=vault_object_attrs(), ...)
#' list_versions()
#' set_version(version=NULL)
#' delete(confirm=TRUE)
#' ```
#' @section Arguments:
#' - `attributes`: For `update_attributes`, the new attributes for the object, such as the expiry date and activation date. A convenient way to provide this is via the [vault_object_attrs] helper function.
#' - `...`: For `update_attributes`, additional secret-specific properties to update. See [secrets].
#' - `version`: For `set_version`, the version ID or NULL for the current version.
#' - `confirm`: For `delete`, whether to ask for confirmation before deleting the secret.
#'
#' @section Details:
#' A secret can have multiple _versions_, which are automatically generated when a secret is created with the same name as an existing secret. By default, the most recent (current) version is used for secret operations; use `list_versions` and `set_version` to change the version.
#'
#' The value is stored as an object of S3 class "secret_value", which has a print method that hides the value to guard against shoulder-surfing. Note that this will not stop a determined attacker; as a general rule, you should minimise assigning secrets or passing them around your R environment. If you want the raw string value itself, eg when passing it to `jsonlite::toJSON` or other functions which do not accept arbitrary object classes as inputs, use `unclass` to strip the class attribute first.
#'
#' @section Value:
#' For `list_versions`, a data frame containing details of each version.
#'
#' For `set_version`, the secret object with the updated version.
#'
#' @seealso
#' [secrets]
#'
#' [Azure Key Vault documentation](https://learn.microsoft.com/en-us/azure/key-vault/),
#' [Azure Key Vault API reference](https://learn.microsoft.com/en-us/rest/api/keyvault)
#'
#' @examples
#' \dontrun{
#'
#' vault <- key_vault("mykeyvault")
#'
#' vault$secrets$create("mynewsecret", "secret text")
#' # new version of an existing secret
#' vault$secrets$create("mynewsecret", "extra secret text"))
#'
#' secret <- vault$secrets$get("mynewsecret")
#' vers <- secret$list_versions()
#' secret$set_version(vers[2])
#'
#' # printing the value will not show the secret
#' secret$value  # "<hidden>"
#'
#' }
#' @name storage_account
#' @rdname storage_account
NULL

stored_secret <- R6::R6Class("stored_secret", inherit=stored_object,

public=list(

    type="secrets",

    id=NULL,
    kid=NULL,
    value=NULL,
    contentType=NULL,

    initialize=function(...)
    {
        super$initialize(...)

        # basic obfuscation of value to help mitigate shoulder-surfing
        class(self$value) <- "secret_value"
    },

    list_versions=function()
    {
        lst <- lapply(get_vault_paged_list(self$do_operation("versions", version=NULL), self$token), function(props)
        {
            content_type <- if(!is_empty(props$contentType))
                props$contentType
            else NA
            attr <- props$attributes
            data.frame(
                version=basename(props$id),
                content_type=content_type,
                created=int_to_date(attr$created),
                updated=int_to_date(attr$updated),
                expiry=int_to_date(attr$exp),
                not_before=int_to_date(attr$nbf),
                stringsAsFactors=FALSE
            )
        })
        do.call(rbind, lst)
    },

    print=function(...)
    {
        cat("Key Vault stored secret '", self$name, "'\n", sep="")
        cat("  Version:", if(is.null(self$version)) "<default>" else self$version, "\n")
        invisible(self)
    }
))


#' @export
print.secret_value <- function(x, ...)
{
    cat("<hidden>\n")
    invisible(x)
}
