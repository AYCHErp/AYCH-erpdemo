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
package com.ilscipio.cato.webapp.ftl.lang;

import java.util.List;

import com.ilscipio.cato.webapp.ftl.CommonFtlUtil;

import freemarker.core.Environment;
import freemarker.template.TemplateMethodModelEx;
import freemarker.template.TemplateModel;
import freemarker.template.TemplateModelException;

/**
 * Cato: CopyObjectMethod - Helper method to clone (shallow copy) a map or list.
 */
public class CopyObjectMethod implements TemplateMethodModelEx {

    public static final String module = CopyObjectMethod.class.getName();

    /*
     * @see freemarker.template.TemplateMethodModel#exec(java.util.List)
     */
    @SuppressWarnings("unchecked")
    @Override
    public Object exec(List args) throws TemplateModelException {
        if (args == null || args.size() < 1 || args.size() > 2) {
            throw new TemplateModelException("Invalid number of arguments (expected: 1-2)");
        }
        Environment env = CommonFtlUtil.getCurrentEnvironment();
        TemplateModel object = (TemplateModel) args.get(0);
        return LangFtlUtil.copyObject(object, null, env.getObjectWrapper());
    }
    
}
