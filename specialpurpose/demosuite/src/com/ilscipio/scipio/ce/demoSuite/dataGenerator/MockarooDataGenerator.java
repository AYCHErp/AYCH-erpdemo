package com.ilscipio.scipio.ce.demoSuite.dataGenerator;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.ofbiz.base.conversion.ConversionException;
import org.ofbiz.base.conversion.JSONConverters;
import org.ofbiz.base.conversion.JSONConverters.JSONToList;
import org.ofbiz.base.conversion.JSONConverters.ListToJSON;
import org.ofbiz.base.lang.JSON;
import org.ofbiz.base.util.Debug;
import org.ofbiz.base.util.HttpClient;
import org.ofbiz.base.util.HttpClientException;

import com.ilscipio.scipio.ce.demoSuite.dataGenerator.dataObject.DemoDataAddress;
import com.ilscipio.scipio.ce.demoSuite.dataGenerator.dataObject.DemoDataObject;
import com.ilscipio.scipio.ce.demoSuite.dataGenerator.dataObject.DemoDataPerson;
import com.ilscipio.scipio.ce.demoSuite.dataGenerator.dataObject.DemoDataProduct;
import com.ilscipio.scipio.ce.demoSuite.dataGenerator.dataObject.DemoDataUserLogin;

import javolution.util.FastList;
import javolution.util.FastMap;

public class MockarooDataGenerator<T extends DemoDataObject> extends ThirdPartyDataGenerator<T> {
    private static String MOCKAROO_DATA_GENERATOR = "mockaroo";

    private final Class<T> returnObjectClass;

    public MockarooDataGenerator(Class<T> type) {
        this.returnObjectClass = type;
    }

    @Override
    protected List<T> retrieveData(Integer count) {
        HttpClient httpClient = new HttpClient();
        MockarooSettings settings = new MockarooSettings();
        String format = properties.getProperty("demosuite.test.data.provider." + getDataGeneratorName() + ".exportFormat");
        String url = properties.getProperty("demosuite.test.data.provider." + getDataGeneratorName() + ".url") + format + "?key="
                + settings.getQueryParameters().get("key");
        httpClient.setContentType("application/json");
        httpClient.setUrl(url + "&count=" + count + "&array=true");
        ListToJSON listJsonConverter = new JSONConverters.ListToJSON();
        try {
            JSON json = listJsonConverter.convert(settings.getFields());
            Debug.log(json.toString());
            httpClient.setRawStream(json.toString());
        } catch (ConversionException e1) {
            Debug.logError(e1.getMessage(), "");
        }

        try {
            String r = httpClient.sendHttpRequest(settings.getMethod());
            return handleData(r, format);

        } catch (HttpClientException e) {
            throw new RuntimeException(e);
        }
    }

    @Override
    protected String getDataGeneratorName() {
        return MOCKAROO_DATA_GENERATOR;
    }

    public class MockarooSettings extends DataGeneratorSettings {
        private static final long serialVersionUID = 5626474670087711771L;

        private HashMap<String, Object> queryParameters = new HashMap<String, Object>();

        public MockarooSettings() {
            queryParameters.put("key", properties.get("demosuite.test.data.provider." + getDataGeneratorName() + ".key"));
        }

        // @Override
        public HashMap<String, Object> getQueryParameters() {
            // demosuite.test.data.provider.mockaroo.queryParams = key,
            // callback, count, array, include_header, schema, delimiter, fields
            return queryParameters;
        }

        @Override
        public List<Object> getFields() {
            List<Object> fields = new ArrayList<Object>();
            if (returnObjectClass.equals(DemoDataAddress.class)) {
                Map<String, Object> country = FastMap.newInstance();
                country.put("name", "country");
                country.put("type", "Country");

                Map<String, Object> state = FastMap.newInstance();
                state.put("name", "state");
                state.put("type", "State");

                Map<String, Object> city = FastMap.newInstance();
                city.put("name", "city");
                city.put("type", "City");

                Map<String, Object> street = FastMap.newInstance();
                street.put("name", "street");
                street.put("type", "Street Name");

                Map<String, Object> zip = FastMap.newInstance();
                zip.put("name", "zip");
                zip.put("type", "Postal Code");

                fields.add(country);
                fields.add(state);
                fields.add(city);
                fields.add(street);
                fields.add(zip);
            } else if (returnObjectClass.equals(DemoDataProduct.class)) {
                Map<String, Object> id = FastMap.newInstance();
                id.put("name", "id");
                id.put("type", "Row Number");

                Map<String, Object> name = FastMap.newInstance();
                name.put("name", "name");
                name.put("type", "Words");
                name.put("min", 1);
                name.put("max", 3);

                Map<String, Object> description = FastMap.newInstance();
                description.put("name", "description");
                description.put("type", "Words");
                description.put("min", 5);
                description.put("max", 15);

                Map<String, Object> longDescription = FastMap.newInstance();
                longDescription.put("name", "longDescription");
                longDescription.put("type", "Sentences");
                longDescription.put("min", 1);
                longDescription.put("max", 3);

                Map<String, Object> price = FastMap.newInstance();
                price.put("name", "price");
                price.put("type", "Money");

                fields.add(id);
                fields.add(name);
                fields.add(description);
                fields.add(longDescription);
                fields.add(price);
            } else if (returnObjectClass.equals(DemoDataPerson.class)) {
                Map<String, Object> title = FastMap.newInstance();
                title.put("name", "title");
                title.put("type", "Title");

                Map<String, Object> firstName = FastMap.newInstance();
                firstName.put("name", "firstName");
                firstName.put("type", "First Name");

                Map<String, Object> lastName = FastMap.newInstance();
                lastName.put("name", "lastName");
                lastName.put("type", "Last Name");

                Map<String, Object> gender = FastMap.newInstance();
                gender.put("name", "gender");
                gender.put("type", "Gender");

                fields.add(title);
                fields.add(firstName);
                fields.add(lastName);
                fields.add(gender);
            } else if (returnObjectClass.equals(DemoDataUserLogin.class)) {
                Map<String, Object> userLoginId = FastMap.newInstance();
                userLoginId.put("name", "userLoginId");
                userLoginId.put("type", "Username");

                Map<String, Object> password = FastMap.newInstance();
                password.put("name", "currentPassword");
                password.put("type", "Password");

                fields.add(userLoginId);
                fields.add(password);
            }
            return fields;
        }

    }

    @Override
    List<T> handleData(String result, String format) {
        if (format.equals("json")) {
            try {
                JSONToList jsonListConverter = new JSONConverters.JSONToList();
                List<T> resultList = FastList.newInstance();
                for (Object o : jsonListConverter.convert(JSON.from(result))) {
                    resultList.add((T) JSON.from(o).toObject(returnObjectClass));
                }
                return resultList;
            } catch (ConversionException e) {
                Debug.logError(e.getMessage(), "");
            } catch (IOException e) {
                Debug.logError(e.getMessage(), "");
            }
        } else {
            throw new UnsupportedOperationException("Export format " + format + " currently not supported");
        }
        return null;
    }

}
