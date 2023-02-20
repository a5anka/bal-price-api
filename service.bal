import ballerina/http;
import ballerina/time;

configurable string productApiUrl = ?;

const string EXCHANGE_RATE_API_URL = "https://api.exchangerate.host";

type PricingInfo record {
    string currencyCode;
    decimal amount;
    string validUntil;
};

// Pricing service is used to calculate the price of a product.
service / on new http:Listener(9090) {

    // Return the price of a product from the product code and the currency code.
    // + productCode - The product code
    // + currencyCode - The currency code
    // + return - Product details
    resource function get price/[string productCode](string currencyCode) returns PricingInfo|error {

        // Call product service to get the product details
        http:Client productClient = check new(productApiUrl);
        json productResponse = check productClient->/product/[productCode]({
            "Accept": "application/json"
        });

        // Create client to call the exchange service
        http:Client exchangeClient = check new(EXCHANGE_RATE_API_URL);


        string fromCurrency = check productResponse.Product.PriceCurrency;
        string price = check productResponse.Product.Price;
        // Call exchange service to get the exchange rate convert?from=USD&to=EUR&amount=100
        json exchangeResponse = check exchangeClient->/convert('from = fromCurrency, to = currencyCode, amount = price);

        PricingInfo product = {
            currencyCode: currencyCode,
            amount: check exchangeResponse.result,
            validUntil: time:utcToString(time:utcAddSeconds(time:utcNow(), 3600 * 60))
        };

        return product;
    }
}
