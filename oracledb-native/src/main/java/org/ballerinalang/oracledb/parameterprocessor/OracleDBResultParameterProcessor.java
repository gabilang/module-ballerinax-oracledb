/*
 *  Copyright (c) 2021, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 *  WSO2 Inc. licenses this file to you under the Apache License,
 *  Version 2.0 (the "License"); you may not use this file except
 *  in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

package org.ballerinalang.oracledb.parameterprocessor;

import io.ballerina.runtime.api.PredefinedTypes;
import io.ballerina.runtime.api.creators.TypeCreator;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.TypeTags;
import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.types.*;
import io.ballerina.runtime.api.values.BArray;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BObject;
import io.ballerina.runtime.api.values.BString;
import org.ballerinalang.oracledb.Constants;
import org.ballerinalang.oracledb.utils.ModuleUtils;
import org.ballerinalang.sql.exception.ApplicationError;
import org.ballerinalang.sql.parameterprocessor.DefaultResultParameterProcessor;

import static io.ballerina.runtime.api.utils.StringUtils.fromString;

import java.math.BigDecimal;
import java.sql.SQLException;
import java.sql.Struct;

/**
 * This class overrides DefaultResultParameterProcessor to implement methods required convert SQL types into
 * ballerina types and other methods that process the parameters of the result.
 *
 * @since 0.1.0
 */
public class OracleDBResultParameterProcessor extends DefaultResultParameterProcessor {
    private static final ArrayType anydataArrayType = TypeCreator.createArrayType(PredefinedTypes.TYPE_ANYDATA);

    private static final OracleDBResultParameterProcessor instance = new OracleDBResultParameterProcessor();
    private static final BObject iterator = ValueCreator.createObjectValue(
            ModuleUtils.getModule(), Constants.CUSTOM_RESULT_ITERATOR_OBJECT, new Object[0]);

    /**
     * Singleton static method that returns an instance of `OracleDBResultParameterProcessor`.
     *
     * @return OracleDBResultParameterProcessor
     */
    public static OracleDBResultParameterProcessor getInstance() {
        return instance;
    }

    @Override
    protected BObject getIteratorObject() {
        return iterator;
    }

    @Override
    protected BMap<BString, Object> createUserDefinedType(Struct structValue, StructureType structType)
            throws ApplicationError {
        if (structValue == null) {
            return null;
        }
        Field[] internalStructFields = structType.getFields().values().toArray(new Field[0]);
        BMap<BString, Object> struct = ValueCreator.createMapValue();
        BArray attributes = ValueCreator.createArrayValue(anydataArrayType);
        try {
            if (!structType.getName().equals("ObjectType") && internalStructFields.length !=1) {
                throw new ApplicationError("specified record is not compatible with the ObjectType.");
            }
            Field internalField = internalStructFields[0];
            Object[] dataArray = structValue.getAttributes();
            if (dataArray != null) {

//                int index = 0;
                for (Object value : dataArray) {
//                    int type = ((BObject) attribute).getType().getTag();
//                    int type = internalField.getFieldType().getTag();
//                    BString fieldName = fromString(internalField.getFieldName());
//                    Object value = dataArray[index];
                    switch (type) {
                        case TypeTags.INT_TAG:
                            if (value instanceof BigDecimal) {
                                attributes.append(((BigDecimal) value).intValue());
                            } else {
                                attributes.append(value);
                            }
                            break;
                        case TypeTags.FLOAT_TAG:
                            if (value instanceof BigDecimal) {
                                attributes.append(((BigDecimal) value).doubleValue());
                            } else {
                                attributes.append(value);
                            }
                            break;
                        case TypeTags.DECIMAL_TAG:
                            if (value instanceof BigDecimal) {
                                attributes.append(value);
                            } else {
                                attributes.append(ValueCreator.createDecimalValue((BigDecimal) value));
                            }
                            break;
                        case TypeTags.STRING_TAG:
                            attributes.append(value);
                            break;
                        case TypeTags.BOOLEAN_TAG:
                            attributes.append(((int) value) == 1);
                            break;
                        case TypeTags.OBJECT_TYPE_TAG:
                        case TypeTags.RECORD_TYPE_TAG:
                            attributes.append(createUserDefinedType((Struct) value, structType));
                            break;
                        default:
                            createUserDefinedTypeSubtype(internalField, structType);
                    }
                    ++index;
                }
            }
            struct.put(StringUtils.fromString(internalField.getFieldName()), attributes);
        } catch (SQLException e) {
            throw new ApplicationError("Error while retrieving data to create " + structType.getName()
                    + " record. ", e);
        }
        return struct;
    }
}

