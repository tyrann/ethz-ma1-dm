import sys
import numpy as np

classes=["nature", "people"]

html_template = open("template.html","r")
html_out = html_template.read()
html_template.close()

html_out_file = open("results.html","wb")

prediction_file = "prediction.csv"
target_file = "target.csv"

predicted_list = np.loadtxt(open(prediction_file, "rb"))
target_list = np.loadtxt(open(target_file, "rb"))

#convert -1 to 0 
predicted_list = (predicted_list+1)/2
target_list = (target_list+1)/2
predicted_list = predicted_list.astype(int)
target_list = target_list.astype(int)

class_correct = [[], []]
class_incorrect = [[], []]

class_counters = [0, 0]
for i in range(len(predicted_list)):
        class_counters[target_list[i]] = class_counters[target_list[i]] + 1
        if predicted_list[i] == target_list[i]:
                html_line = "<img width='100px'' src=\"images/"+str(classes[target_list[i]]) + "_" + str(class_counters[target_list[i]])+ ".jpeg\">"
                class_correct[predicted_list[i]].append(html_line)
        else:
                html_line = "<img width='100px' src=\"images/"+str(classes[target_list[i]]) + "_" + str(class_counters[target_list[i]])+ ".jpeg\">"
                class_incorrect[predicted_list[i]].append(html_line)

num_errors = np.sum(abs(predicted_list - target_list))
perc_accuracy = 100-(100*num_errors/len(predicted_list))

print "Classification accuracy: " + str(perc_accuracy) + "%"
print "Check it visually by opening results.html"

html_out = html_out.replace("class_0_correct", "\n".join(class_correct[0]))
html_out = html_out.replace("class_1_correct", "\n".join(class_correct[1]))
html_out = html_out.replace("class_0_incorrect", "\n".join(class_incorrect[0]))
html_out = html_out.replace("class_1_incorrect", "\n".join(class_incorrect[1]))

html_out_file.write(html_out)
html_out_file.close()
