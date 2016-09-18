/*******************************************************************************
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *******************************************************************************/
package org.ofbiz.webapp.website;

import javax.servlet.http.HttpServletRequest;

import org.ofbiz.base.lang.ThreadSafe;
import org.ofbiz.base.start.Start;
import org.ofbiz.base.util.Assert;
import org.ofbiz.entity.Delegator;
import org.ofbiz.entity.GenericEntityException;
import org.ofbiz.entity.GenericValue;
import org.ofbiz.entity.util.EntityQuery;
import org.ofbiz.entity.util.EntityUtilProperties;

/**
 * Web site properties.
 */
@ThreadSafe
public final class WebSiteProperties {


    /**
     * Returns a <code>WebSiteProperties</code> instance initialized to the settings found
     * in the <code>url.properties</code> file.
     */
    public static WebSiteProperties defaults(Delegator delegator) {
        return new WebSiteProperties(delegator);
    }

    /**
     * Returns a <code>WebSiteProperties</code> instance initialized to the settings found
     * in the application's WebSite entity value. If the application does not have a
     * WebSite entity value then the instance is initialized to the settings found
     * in the <code>url.properties</code> file.
     * 
     * @param request
     * @throws GenericEntityException
     */
    public static WebSiteProperties from(HttpServletRequest request) throws GenericEntityException {
        Assert.notNull("request", request);
        WebSiteProperties webSiteProps = (WebSiteProperties) request.getAttribute("_WEBSITE_PROPS_");
        if (webSiteProps == null) {

            // SCIPIO: now delegates
            webSiteProps = newFrom(request, WebSiteWorker.getWebSiteId(request));
            
            request.setAttribute("_WEBSITE_PROPS_", webSiteProps);
        }
        return webSiteProps;
    }
    
    private static WebSiteProperties newFrom(HttpServletRequest request, String webSiteId) throws GenericEntityException {
        Delegator delegator = (Delegator) request.getAttribute("delegator");
        
        // SCIPIO: This code section is restructured for optional request overrides and other fixes.
        
        boolean overrideRequestHostPort = "Y".equalsIgnoreCase(EntityUtilProperties.getPropertyValue("url.properties", "override.request.host.port", delegator));
        boolean requestOverridesStatic = !overrideRequestHostPort;
        boolean requestOverridesStaticHttpPort = requestOverridesStatic;
        boolean requestOverridesStaticHttpHost = requestOverridesStatic;
        boolean requestOverridesStaticHttpsPort = requestOverridesStatic;
        boolean requestOverridesStaticHttpsHost = requestOverridesStatic;
        
        WebSiteProperties defaults = new WebSiteProperties(delegator);
        
        String httpPort = defaults.getHttpPort();
        String httpHost = defaults.getHttpHost();
        String httpsPort = defaults.getHttpsPort();
        String httpsHost = defaults.getHttpsHost();
        boolean enableHttps = defaults.getEnableHttps();
        
        if (delegator != null) {
            if (webSiteId != null) {
                GenericValue webSiteValue = EntityQuery.use(delegator).from("WebSite").where("webSiteId", webSiteId).cache().queryOne();
                if (webSiteValue != null) {
                    if (webSiteValue.get("httpPort") != null) {
                        httpPort = webSiteValue.getString("httpPort");
                        requestOverridesStaticHttpPort = false;
                    }
                    if (webSiteValue.get("httpHost") != null) {
                        httpHost = webSiteValue.getString("httpHost");
                        requestOverridesStaticHttpHost = false;
                    }
                    if (webSiteValue.get("httpsPort") != null) {
                        httpsPort = webSiteValue.getString("httpsPort");
                        requestOverridesStaticHttpsPort = false;
                    }
                    if (webSiteValue.get("httpsHost") != null) {
                        httpsHost = webSiteValue.getString("httpsHost");
                        requestOverridesStaticHttpsHost = false;
                    }
                    if (webSiteValue.get("enableHttps") != null) {
                        enableHttps = webSiteValue.getBoolean("enableHttps");
                    }
                }
            }
        }
        
        // SCIPIO: NOTE: this has been factored and moved to before the request value lookups.
        httpPort = adjustPort(delegator, httpPort);
        httpsPort = adjustPort(delegator, httpsPort);      
        
        // SCIPIO: this may override the url.properties settings, though not the WebSite settings
        if ((requestOverridesStaticHttpPort || httpPort.isEmpty()) && !request.isSecure()) {
            httpPort = String.valueOf(request.getServerPort());
        }
        if (requestOverridesStaticHttpHost || httpHost.isEmpty()) {
            httpHost = request.getServerName();
        }
        if ((requestOverridesStaticHttpsPort || httpsPort.isEmpty()) && request.isSecure()) {
            httpsPort = String.valueOf(request.getServerPort());
        }
        if (requestOverridesStaticHttpsHost || httpsHost.isEmpty()) {
            httpsHost = request.getServerName();
        }

        return new WebSiteProperties(httpPort, httpHost, httpsPort, httpsHost, enableHttps);
    }
    
    /**
     * SCIPIO: Returns web site properties for the given web site; any host or port fields
     * not specified are taken from request instead, as would be returned by {@link #from(HttpServletRequest)}.
     * 
     * @param webSiteValue
     */
    public static WebSiteProperties from(HttpServletRequest request, GenericValue webSiteValue) throws GenericEntityException {
        Assert.notNull("webSiteValue", webSiteValue);
        if (!"WebSite".equals(webSiteValue.getEntityName())) {
            throw new IllegalArgumentException("webSiteValue is not a WebSite entity value");
        }
        
        WebSiteProperties defaults = from(request);
                
        String httpPort;
        boolean adjustHttpPort;
        if (webSiteValue.get("httpPort") != null) {
            httpPort = webSiteValue.getString("httpPort");
            adjustHttpPort = true;
        } else {
            httpPort = defaults.getHttpPort();
            adjustHttpPort = false;
        }
        String httpHost = (webSiteValue.get("httpHost") != null) ? webSiteValue.getString("httpHost") : defaults.getHttpHost();
        String httpsPort;
        boolean adjustHttpsPort;
        if (webSiteValue.get("httpsPort") != null) {
            httpsPort = webSiteValue.getString("httpsPort");
            adjustHttpsPort = true;
        } else {
            httpsPort = defaults.getHttpsPort();
            adjustHttpsPort = false;
        }
        String httpsHost = (webSiteValue.get("httpsHost") != null) ? webSiteValue.getString("httpsHost") : defaults.getHttpsHost();
        boolean enableHttps = (webSiteValue.get("enableHttps") != null) ? webSiteValue.getBoolean("enableHttps") : defaults.getEnableHttps();

        if (adjustHttpPort) {
            httpPort = adjustPort(webSiteValue.getDelegator(), httpPort);
        }
        if (adjustHttpsPort) {
            httpsPort = adjustPort(webSiteValue.getDelegator(), httpsPort);
        }
        
        return new WebSiteProperties(httpPort, httpHost, httpsPort, httpsHost, enableHttps);
    }
    
    /**
     * SCIPIO: Returns web site properties for the given webSiteId, or for any fields missing,
     * the values for the current request (or system defaults).
     * 
     * @param webSiteValue
     */
    public static WebSiteProperties from(HttpServletRequest request, String webSiteId) throws GenericEntityException {
        Assert.notNull("webSiteId", webSiteId);
        Delegator delegator = (Delegator) request.getAttribute("delegator");
        GenericValue webSiteValue = EntityQuery.use(delegator).from("WebSite").where("webSiteId", webSiteId).cache().queryOne();
        if (webSiteValue != null) {
            return from(request, webSiteValue);
        } else {
            throw new GenericEntityException("Scipio: Could not find WebSite for webSiteId '" + webSiteId + "'");
        }
    }
    
    
    /**
     * Returns a <code>WebSiteProperties</code> instance initialized to the settings found
     * in the WebSite entity value.
     * 
     * @param webSiteValue
     */
    public static WebSiteProperties from(GenericValue webSiteValue) {
        Assert.notNull("webSiteValue", webSiteValue);
        if (!"WebSite".equals(webSiteValue.getEntityName())) {
            throw new IllegalArgumentException("webSiteValue is not a WebSite entity value");
        }
        WebSiteProperties defaults = new WebSiteProperties(webSiteValue.getDelegator());
        String httpPort = (webSiteValue.get("httpPort") != null) ? webSiteValue.getString("httpPort") : defaults.getHttpPort();
        String httpHost = (webSiteValue.get("httpHost") != null) ? webSiteValue.getString("httpHost") : defaults.getHttpHost();
        String httpsPort = (webSiteValue.get("httpsPort") != null) ? webSiteValue.getString("httpsPort") : defaults.getHttpsPort();
        String httpsHost = (webSiteValue.get("httpsHost") != null) ? webSiteValue.getString("httpsHost") : defaults.getHttpsHost();
        boolean enableHttps = (webSiteValue.get("enableHttps") != null) ? webSiteValue.getBoolean("enableHttps") : defaults.getEnableHttps();

        // SCIPIO: factored out
        httpPort = adjustPort(webSiteValue.getDelegator(), httpPort);
        httpsPort = adjustPort(webSiteValue.getDelegator(), httpsPort);            
        
        return new WebSiteProperties(httpPort, httpHost, httpsPort, httpsHost, enableHttps);
    }
    
    /**
     * SCIPIO: Returns a <code>WebSiteProperties</code> instance initialized to the settings found
     * in the WebSite entity value for the given webSiteId.
     * 
     * @param delegator
     * @param webSiteId
     */
    public static WebSiteProperties from(Delegator delegator, String webSiteId) throws GenericEntityException {
        Assert.notNull("webSiteId", webSiteId);
        GenericValue webSiteValue = EntityQuery.use(delegator).from("WebSite").where("webSiteId", webSiteId).cache().queryOne();
        if (webSiteValue != null) {
            return from(webSiteValue);
        } else {
            throw new GenericEntityException("Scipio: Could not find WebSite for webSiteId '" + webSiteId + "'");
        }
    }    

    private final String httpPort;
    private final String httpHost;
    private final String httpsPort;
    private final String httpsHost;
    private final boolean enableHttps;

    private WebSiteProperties(Delegator delegator) {
        this.httpPort = EntityUtilProperties.getPropertyValue("url.properties", "port.http", delegator);
        this.httpHost = EntityUtilProperties.getPropertyValue("url.properties", "force.http.host", delegator);
        this.httpsPort = EntityUtilProperties.getPropertyValue("url.properties", "port.https", delegator);
        this.httpsHost = EntityUtilProperties.getPropertyValue("url.properties", "force.https.host", delegator);
        this.enableHttps = EntityUtilProperties.propertyValueEqualsIgnoreCase("url.properties", "port.https.enabled", "Y", delegator);
    }

    private WebSiteProperties(String httpPort, String httpHost, String httpsPort, String httpsHost, boolean enableHttps) {
        this.httpPort = httpPort;
        this.httpHost = httpHost;
        this.httpsPort = httpsPort;
        this.httpsHost = httpsHost;
        this.enableHttps = enableHttps;
    }

    /**
     * Returns the configured http port, or an empty <code>String</code> if not configured.
     */
    public String getHttpPort() {
        return httpPort;
    }

    /**
     * Returns the configured http host, or an empty <code>String</code> if not configured.
     */
    public String getHttpHost() {
        return httpHost;
    }

    /**
     * Returns the configured https port, or an empty <code>String</code> if not configured.
     */
    public String getHttpsPort() {
        return httpsPort;
    }

    /**
     * Returns the configured https host, or an empty <code>String</code> if not configured.
     */
    public String getHttpsHost() {
        return httpsHost;
    }

    /**
     * Returns <code>true</code> if https is enabled.
     */
    public boolean getEnableHttps() {
        return enableHttps;
    }

    @Override
    public String toString() {
        StringBuilder sb = new StringBuilder("{httpPort=");
        sb.append(httpPort).append(", ");
        sb.append("httpHost=").append(httpHost).append(", ");
        sb.append("httpsPort=").append(httpsPort).append(", ");
        sb.append("httpsHost=").append(httpsHost).append(", ");
        sb.append("enableHttps=").append(enableHttps).append("}");
        return sb.toString();
    }
    
    /**
     * SCIPIO: Returns true if and only if all fields in this object match 
     * the ones in the other WebSiteProperties.
     * 
     * @see java.lang.Object#equals(java.lang.Object)
     */
    @Override
    public boolean equals(Object other) {
        if (this == other) {
            return true;
        }
        else if (other == null) {
            return false;
        }
        else if (!(other instanceof WebSiteProperties)) {
            return false;
        }
        WebSiteProperties o = (WebSiteProperties) other;
        return sameFields(this.httpHost, o.httpHost) &&
               sameFields(this.httpPort, o.httpPort) &&
               sameFields(this.httpsHost, o.httpsHost) &&
               sameFields(this.httpsPort, o.httpsPort) &&
               (this.enableHttps == o.enableHttps);
    }
    
    /**
     * SCIPIO: Returns true if and only if all fields in this object match 
     * the ones in the other WebSiteProperties. Fields which are missing, 
     * such as hosts or ports, are substituted with hardcoded Ofbiz defaults when 
     * performing the comparison.
     * <p>
     * Currently, the hard defaults are "localhost" for host fields, "80" for httpPort
     * and "443" for httpsPort. 
     * 
     * @see java.lang.Object#equals(java.lang.Object)
     */
    public boolean equalsWithHardDefaults(Object other) {
        if (this == other) {
            return true;
        }
        else if (other == null) {
            return false;
        }
        else if (!(other instanceof WebSiteProperties)) {
            return false;
        }
        WebSiteProperties o = (WebSiteProperties) other;
        return sameFields(this.httpHost, o.httpHost, "localhost") &&
               sameFields(this.httpPort, o.httpPort, "80") &&
               sameFields(this.httpsHost, o.httpsHost, "localhost") &&
               sameFields(this.httpsPort, o.httpsPort, "443") &&
               (this.enableHttps == o.enableHttps);
    }
    
    private static boolean sameFields(String first, String second) {
        // SCIPIO: treat null and empty the same, just to be safe
        if (first != null && !first.isEmpty()) {
            return first.equals(second);
        }
        else {
            return (second == null || second.isEmpty());
        }
    }
    
    private static boolean sameFields(String first, String second, String defaultVal) {
        if (first == null || first.isEmpty()) {
            first = defaultVal;
        }
        if (second == null || second.isEmpty()) {
            second = defaultVal;
        }
        return first.equals(second);
    }
    
    /**
     * SCIPIO: Adjusts the given port value (as string) by the port offset configuration value, if applicable.
     */
    public static String adjustPort(Delegator delegator, String port) {
        if (port != null && !port.isEmpty() && Start.getInstance().getConfig().portOffset != 0) {
            Integer portValue = Integer.valueOf(port);
            portValue += Start.getInstance().getConfig().portOffset;
            return portValue.toString();
        } else {
            return port;
        }
    }
    
    /**
     * SCIPIO: Adjusts the given port value by the port offset configuration value, if applicable.
     */
    public static Integer adjustPort(Delegator delegator, Integer port) {
        if (port != null && Start.getInstance().getConfig().portOffset != 0) {
            return port + Start.getInstance().getConfig().portOffset;
        } else {
            return port;
        }
    }
}
