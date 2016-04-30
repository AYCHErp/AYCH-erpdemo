<#--
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
-->
<#include "customercommon.ftl">

<#-- Cato: EFT account fields, originally from editeftaccount.ftl 
  for pre-fill, requires:
    eftAccountData 
    paymentMethodData
-->

<@field type="input" label="${uiLabelMap.AccountingNameOnAccount}" required=true size="30" maxlength="60" name="${fieldNamePrefix}nameOnAccount" value=(parameters["${fieldNamePrefix}nameOnAccount"]!(eftAccountData.nameOnAccount)!(eafFallbacks.nameOnAccount)!) />
<@field type="input" label="${uiLabelMap.AccountingCompanyNameOnAccount}" size="30" maxlength="60" name="${fieldNamePrefix}companyNameOnAccount" value=(parameters["${fieldNamePrefix}companyNameOnAccount"]!(eftAccountData.companyNameOnAccount)!(eafFallbacks.companyNameOnAccount)!) />
<@field type="input" label="${uiLabelMap.AccountingBankName}" required=true size="30" maxlength="60" name="${fieldNamePrefix}bankName" value=(parameters["${fieldNamePrefix}bankName"]!(eftAccountData.bankName)!(eafFallbacks.bankName)!) />
<@field type="input" label="${uiLabelMap.AccountingRoutingNumber}" required=true size="10" maxlength="30" name="${fieldNamePrefix}routingNumber" value=(parameters["${fieldNamePrefix}routingNumber"]!(eftAccountData.routingNumber)!(eafFallbacks.routingNumber)!) />
<@field type="select" label="${uiLabelMap.AccountingAccountType}" required=true name="${fieldNamePrefix}accountType">
  <#assign selectedAccountType = (parameters["${fieldNamePrefix}accountType"]!(eftAccountData.accountType)!(eafFallbacks.accountType)!)>
  <#-- Cato: NOTE: These type names are very loosely defined... -->
  <#if !["Checking", "Savings"]?seq_contains(selectedAccountType)>
    <option value="${selectedAccountType}">${eftAccountData.accountType!}</option>
    <option></option>
  </#if>
  <option<#if selectedAccountType == "Checking"> value="Checking"</#if>>${uiLabelMap.CommonChecking}</option>
  <option<#if selectedAccountType == "Savings"> value="Savings"</#if>>${uiLabelMap.CommonSavings}</option>
</@field>
<@field type="input" label="${uiLabelMap.AccountingAccountNumber}" required=true size="20" maxlength="40" name="${fieldNamePrefix}accountNumber" value=(parameters["${fieldNamePrefix}accountNumber"]!(eftAccountData.accountNumber)!(eafFallbacks.accountNumber)!) />
<@field type="input" label="${uiLabelMap.CommonDescription}" size="30" maxlength="60" name="${fieldNamePrefix}description" value=(parameters["${fieldNamePrefix}description"]!(paymentMethodData.description)!(eafFallbacks.description)!) />


   

