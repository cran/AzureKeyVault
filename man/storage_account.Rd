% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/stored_acct.R, R/stored_secret.R
\docType{class}
\name{storage_account}
\alias{storage_account}
\title{Managed storage account}
\description{
This class represents a storage account that Key Vault will manage access to. It provides methods for regenerating keys, and managing shared access signatures (SAS).

This class represents a secret stored in a vault.
}
\section{Fields}{

This class provides the following fields:
\itemize{
\item \code{id}: The internal vault ID of the storage account.
\item \code{resourceId}: The Azure resource ID of the storage account.
\item \code{activeKeyName}: The current active storage account key.
\item \code{autoRegenerateKey}: Whether Key Vault will manage the storage account's key.
\item \code{regenerationPeriod}: How often the account key is regenerated, in ISO 8601 format.
}


This class provides the following fields:
\itemize{
\item \code{value}: The value of the secret.
\item \code{id}: The ID of the secret.
\item \code{kid}: If this secret backs a certificate, the ID of the corresponding key.
\item \code{managed}: Whether this secret's lifetime is managed by Key Vault. TRUE if the secret backs a certificate.
\item \code{contentType}: The content type of the secret.
}
}

\section{Methods}{

This class provides the following methods:

\if{html}{\out{<div class="sourceCode">}}\preformatted{regenerate_key(key_name)
create_sas_definition(sas_name, sas_template, validity_period, sas_type="account",
                      enabled=TRUE, recovery_level=NULL, ...)
delete_sas_definition(sas_name, confirm=TRUE)
get_sas_definition(sas_name)
list_sas_definitions()
show_sas(sas_name)

update_attributes(attributes=vault_object_attrs(), ...)
remove(confirm=TRUE)
}\if{html}{\out{</div>}}


This class provides the following methods:

\if{html}{\out{<div class="sourceCode">}}\preformatted{update_attributes(attributes=vault_object_attrs(), ...)
list_versions()
set_version(version=NULL)
delete(confirm=TRUE)
}\if{html}{\out{</div>}}
}

\section{Arguments}{

\itemize{
\item \code{key_name}: For \code{regenerate_key}, the name of the access key to regenerate.
\item \code{sas_name}: The name of a SAS definition.
\item \code{sas_template}: A string giving the details of the SAS to create. See 'Details' below.
\item \code{validity_period}: How long the SAS should be valid for.
\item \code{sas_type}: The type of SAS to generate, either "account" or "service".
\item \code{enabled}: Whether the SAS definition. is enabled.
\item \code{recovery_level}: The recovery level of the SAS definition.
\item \code{...}: For \code{create_sas_definition}, other named arguments to use as tags for a SAS definition. For \code{update_attributes}, additional account-specific properties to update. See \link{storage_accounts}.
\item \code{attributes}: For \code{update_attributes}, the new attributes for the object, such as the expiry date and activation date. A convenient way to provide this is via the \link{vault_object_attrs} helper function.
\item \code{confirm}: For \code{delete} and \code{delete_sas_definition}, whether to ask for confirmation before deleting.
}


\itemize{
\item \code{attributes}: For \code{update_attributes}, the new attributes for the object, such as the expiry date and activation date. A convenient way to provide this is via the \link{vault_object_attrs} helper function.
\item \code{...}: For \code{update_attributes}, additional secret-specific properties to update. See \link{secrets}.
\item \code{version}: For \code{set_version}, the version ID or NULL for the current version.
\item \code{confirm}: For \code{delete}, whether to ask for confirmation before deleting the secret.
}
}

\section{Details}{

\code{create_sas_definition} creates a new SAS definition from a template. This can be created from the Azure Portal, via the Azure CLI, or in R via the AzureStor package (see examples). \code{get_sas_definition} returns a list representing the template definition; \code{show_sas} returns the actual SAS.

\code{regenerate_key} manually regenerates an access key. Note that if the vault is setup to regenerate keys automatically, you won't usually have to use this method.

Unlike the other objects stored in a key vault, storage accounts are not versioned.


A secret can have multiple \emph{versions}, which are automatically generated when a secret is created with the same name as an existing secret. By default, the most recent (current) version is used for secret operations; use \code{list_versions} and \code{set_version} to change the version.

The value is stored as an object of S3 class "secret_value", which has a print method that hides the value to guard against shoulder-surfing. Note that this will not stop a determined attacker; as a general rule, you should minimise assigning secrets or passing them around your R environment. If you want the raw string value itself, eg when passing it to \code{jsonlite::toJSON} or other functions which do not accept arbitrary object classes as inputs, use \code{unclass} to strip the class attribute first.
}

\section{Value}{

For \code{create_sas_definition} and \code{get_sas_definition}, a list representing the SAS definition. For \code{list_sas_definitions}, a list of such lists.

For \code{show_sas}, a string containing the SAS.


For \code{list_versions}, a data frame containing details of each version.

For \code{set_version}, the secret object with the updated version.
}

\examples{
\dontrun{

vault <- key_vault("mykeyvault")

# get the storage account details
library(AzureStor)
res <- AzureRMR::get_azure_login()$
    get_subscription("sub_id")$
    get_resource_group("rgname")$
    get_storage_account("mystorageacct")

stor <- vault$storage$create("mystor", res, "key1")

# Creating a new SAS definition
today <- Sys.time()
sasdef <- res$get_account_sas(expiry=today + 7*24*60*60, services="b", permissions="rw")
stor$create_sas_definition("newsas", sasdef, validity_period="P15D")

stor$show_sas("newsas")

}
\dontrun{

vault <- key_vault("mykeyvault")

vault$secrets$create("mynewsecret", "secret text")
# new version of an existing secret
vault$secrets$create("mynewsecret", "extra secret text"))

secret <- vault$secrets$get("mynewsecret")
vers <- secret$list_versions()
secret$set_version(vers[2])

# printing the value will not show the secret
secret$value  # "<hidden>"

}
}
\seealso{
\link{storage_accounts}

\href{https://learn.microsoft.com/en-us/azure/key-vault/}{Azure Key Vault documentation},
\href{https://learn.microsoft.com/en-us/rest/api/keyvault}{Azure Key Vault API reference}

\link{secrets}

\href{https://learn.microsoft.com/en-us/azure/key-vault/}{Azure Key Vault documentation},
\href{https://learn.microsoft.com/en-us/rest/api/keyvault}{Azure Key Vault API reference}
}
