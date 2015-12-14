import numpy

articles_dic = {}
user_feat = numpy.zeros(6)
maxID = 0
alpha = 1 + numpy.sqrt(numpy.log(2/0.1)/2)

def set_articles(articles):
    pass

def update(reward):
    articles_dic[maxID][0] += user_feat * user_feat.T
    articles_dic[maxID][1] += reward*user_feat

def recommend(time, user_features, articles):

    maxUCB = None
    user_feat = user_features
    for id in articles:

        # create or retrieve an entry in the dictionary
        (M_x,b_x) = addToDic(id)

        # initialize weights
        M_x_inv = numpy.linalg.inv(M_x)
        w_t = M_x_inv * b_x

        #set UCBx

        UCBx = numpy.dot(w_t,user_features) + alpha*numpy.sqrt(numpy.transpose(user_features)*M_x_inv*user_features)

        if maxUCB is None or UCBx > maxUCB:
            maxUCB = UCBx
            maxID = id

    return maxID

def addToDic(id):
    if id in articles_dic:
        return articles_dic[id]
    else:
        articles_dic[id] = (numpy.identity(6),numpy.zeros(6))
        return articles_dic[id]
