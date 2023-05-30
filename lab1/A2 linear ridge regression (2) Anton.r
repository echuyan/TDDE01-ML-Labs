#----------------------------lab1. assignment2. linear and ridge regression---------------------------
#setwd("/Users/eli/Desktop/Machine learning/Lab 1/")
#loading the dataset
parkinson=read.csv("parkinsons.csv")
#REMOVE UNNECESSARY COLUMNS FIRST
parkinson$subject.=c()
parkinson$sex=c()
parkinson$test_time=c()
parkinson$age=c()
parkinson$total_UPDRS=c()

#choosing training and test sets
set.seed(12345)
n=nrow(parkinson)
id=sample(1:n, floor(n*0.6))
train=parkinson[id,]
test=parkinson[-id,]


#scaling 
library(caret)
scaler=preProcess(train)
trainS=predict(scaler,train)
testS=predict(scaler,test)

#Compute a linear regression model from the training data, estimate training
#and test MSE and comment on which variables contribute significantly to the model
#no intercept is needed in the modelling


fit = lm(motor_UPDRS~.-1 , data=trainS)

sum=summary(fit)
#calculate MSE for train dataset
MSEtrain=mean(sum$residuals^2)
#run model on test dataset
fitTest=predict(fit,testS,interval = "prediction")
#calculate MSE for test dataset
MSEtest=mean((testS$motor_UPDRS-fitTest)^2)

#comment on which variables contribute significantly to the model.
# Shimmer.DDA
# Shimmer.APQ3
# we scaled the data => resulting coefficients can be compared and we can compare absolute values

#??????question?????????? (significant contribution) - should some other variables be picked? How to define a threshold?
#answer : look at p-values and ***
#CHECK IN GOOGLE
summary(fit)


#Implement 4 following functions

#3a) Log-likelihood function that for a given parameter vector 𝜽 and
#dispersion 𝜎 computes the log-likelihood function log 𝑃(𝑇|𝜽, 𝜎) for
#the stated model and the training data
#Going by that motor_UPDRS is a normal distribution as mentioned in 1.
#Formula log-likelihood F(𝜽)=log(L(𝜽))=sum(over i=1 to n) log(fi(yi|𝜽))

#??????question??????????: is the set of 𝜽we are trying to optimize equal to the vector of coefficients in LR model   - YES
vectorTheta = fit$coefficients
names(vectorTheta) <- NULL
dispersionSigma = summary(fit)$sigma
logLikelihood<-function(theta,sigma){
  #population size n
  
  n<-length(theta)
  #print(n)
  actualValue<-trainS$motor_UPDRS[1:n] #y in the formula. 
  #print(actualValue)
  #print(length(parkinson$motor_UPDRS))
  #ERROR!
  #Expected value, estimated by using the average value.
  #ev=mean(theta) 
  #changed it to transpose of the in parametr theta to match p44 book. 

  predictedTheta=theta
  #print(ev)
  #Done here because when calculations were done in "sum" in the formula, errors appeared.
  x=(predictedTheta-actualValue)^2 #is vector of
  #print("printing x")
  #print(x)
  #ERROR!
 
  #Formula
  result=((-1*n/2)*log(2*pi,base=exp(1))-(n/2)*log(sigma^2,base=exp(1))-1/(2*sigma^2)*sum(x, na.rm=FALSE))
 
  return (result)
}
print(logLikelihood(vectorTheta,dispersionSigma))
logLik(fit)

#3b) Ridge function that for given vector 𝜽𝜽, scalar 𝜎𝜎 and scalar 𝜆𝜆 uses function from 3a and adds up a Ridge penalty 𝜆‖𝜽𝜽‖2 to the minus loglikelihood
mylambda=1

myridge<-function(theta,sigma,lambda){
  
 # print(theta)
  #print(sigma)
  #print(lambda)
  ridgePenalty=lambda*sum(theta^2)
  
  #print(ridgePenalty)
 # print(logLikelihood(theta,sigma ))
  result =  -logLikelihood(theta,sigma )+ ridgePenalty
  
 # print(result)
  return (result)
  
}
print(myridge(vectorTheta,dispersionSigma,mylambda))


# 3c) RidgeOpt function that depends on scalar 𝜆 , uses function from 3b
#and function optim() with method=”BFGS” to find the optimal 𝜽 and 𝜎 for the given 𝜆.
#ANSWER: initiate with 0 and then compare the result of our custom prediction with true values
par1 <- rep(c(0),each=16)
sigmaPar=1
par1 <- append(par1,sigmaPar)
#par1 <- append(par1,dispersionSigma)
#par1 <- append(par1,lambda)
myRidgeOpt=function(lambdaIn) {
  
  
  #result <- optim(par1,fn=myridge,theta=par1[1:64],sigma=par1[65],lambda=par1[66],method="BFGS")
  #resultTheta <- optim(par1,fn=myridge,sigma=dispersionSigma,lambda=lambdaIn,method="BFGS")
  #resultSigma<- optim(dispersionSigma,fn=myridge,theta=par1,lambda=lambdaIn,method="BFGS")
  
  result<- optim(par1,fn=myridge,sigma=sigmaPar,lambda=lambdaIn,method="BFGS")
  
  #WE SHOULD OPTIMIZE THEM TOGETHER
  #result <- resultTheta$par
 
  #result=append(result,resultSigma$par)
  return (result)
}

optimal=myRidgeOpt(mylambda)
print(optimal)
#??????question??????????
#how can we prove that the result is indeed optimal and not erroneous in any way?


#can we build a ridge regression model using glmnet library?
#3d) Df function that for a given scalar 𝜆 computes the degrees of freedom
#of the Ridge model based on the training data
install.packages("glmnet")
library(glmnet)
x <- data.matrix(trainS[, c('Jitter...', 'Jitter.Abs.', 'Jitter.RAP', 'Jitter.PPQ5','Jitter.DDP','Shimmer','Shimmer.dB.','Shimmer.APQ3',
                            'Shimmer.APQ5','Shimmer.APQ11','Shimmer.DDA','NHR','HNR','RPDE','DFA','PPE')])
y<-trainS$motor_UPDRS

ridgeModel=glmnet(x,y,alpha=0)

y_predicted <- predict(ridgeModel, s = 1, newx = x)

#p=16 (16 variables)
lambdaIn=1
DF=function(lambdaIn) {
  #(df)= ∑ni=1(di)2(di)2+λ
  #plan:
  #get A^T*A-lambda*I, I - identity matrix
  #get eigenvalues from that equation
  #calculate degrees of freedom as (df)= ∑j=1,p (dj)^2/((dj)^2+λ), where dj^2 are eigenvalues and p is a number of variables
  #question: will this approach help us find degrees of freedom or are there better approaches to use?
  A<-data.matrix(trainS)
  nxn_matrix=A%*%t(A)
  #print(dim(nxn_matrix))
  n<-nrow(nxn_matrix)
  print(n)
  identitymatrix<-diag(n)
  install.packages("psych")
  library("psych")
  print(tr(identitymatrix))
  y<-det(data.matrix(nxn_matrix-lambdaIn*identitymatrix))
  print(y)

  #print(eigen(y, only.values = TRUE))
  df<-residuals(fit)
  #answer: YES!
}
print(DF(mylambda))
#----------------------------4. -------
#By using function RidgeOpt, compute optimal 𝜽𝜽 parameters for 𝜆𝜆 = 1, 𝜆𝜆 =
#  100 and 𝜆𝜆 = 1000. Use the estimated parameters to predict the
#motor_UPDRS values for training and test data and report the training and
#test MSE values. Which penalty parameter is most appropriate among the
#selected ones? Compute and compare the degrees of freedom of these models
#and make appropriate conclusions.

#sum=summary(fit)
##calculate MSE for train dataset
#MSEtrain=mean(sum$residuals^2)
##run model on test dataset
#fitTest=predict(fit,testS,interval = "prediction")
##calculate MSE for test dataset
#MSEtest=mean((testS$motor_UPDRS-fitTest)^2)


c <- c(1,2,3,4,5)
c <- c[1:3]
