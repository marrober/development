import org.codehaus.jettison.json.JSONObject
import org.codehaus.jettison.json.JSONArray
import groovy.json.JsonSlurper

String filename = args[0]

if (filename.length() == 0) {
  println("Filename required as argument")
  return(0)
}

String fileContents = new File(filename).text

def jsonSlurperComponentTemplates = new JsonSlurper()
def componentTemplates=jsonSlurperComponentTemplates.parseText(fileContents)
def numberComponentTemplates = componentTemplates.size()
println(numberComponentTemplates + " component templates to be analysed.")

for (def counter = 0; counter < numberComponentTemplates; counter++) {
  def componentTemplate = componentTemplates[counter]

  def description = ""
  def name  = ""
  if (componentTemplate.user) {
    def owner = componentTemplate.user

    if (owner.contains("(")) {
      def splitOwner = owner.split("\\(")
      def splitName = splitOwner[0].split(",")
      name = splitName[1] + splitName[0]
      name = name.substring(1, name.length())
    } else {
      name = owner
    }
  } else {
    name = "<missing>"
  }
  if (componentTemplate.description){
    description = componentTemplate.description
  }

  println(componentTemplate.name + "#" + componentTemplate.version + "#" + name + "#" + description)


}
