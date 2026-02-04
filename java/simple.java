import org.json.simple.JSONObject;
import org.json.simple.parser.JSONParser;
import org.json.simple.parser.ParseException;

public class simple {
    public static void main(String[] args) {
        // 1. Create a JSON Object
        JSONObject obj = new JSONObject();
        obj.put("name", "John Doe");
        obj.put("age", 30);
        obj.put("city", "New York");

        System.out.println("Generated JSON: " + obj.toJSONString());

        // 2. Parse a JSON String
        String jsonString = "{\"name\":\"Alice\",\"age\":25}";
        JSONParser parser = new JSONParser();
        try {
            JSONObject parsedObj = (JSONObject) parser.parse(jsonString);
            System.out.println("Parsed Name: " + parsedObj.get("name"));
        } catch (ParseException e) {
            e.printStackTrace();
        }
    }
}