<h1 align="center"> Latent Factor + Sparse Matrix logistic regression model for network data </h1>

<p align="center">
  <a href="#overview">Overview</a> •
  <a href="#quickstart-with-the-data--models">Quickstart</a> •
  <a href="#acknowledgements">Acknowledgements</a> 
</p>

# Overview

- **Model Description** : Our paper proposes a combined model, which integrates the latent factor model and the logistic regression model, for the network data. It is noticed that neither a latent factor model nor a logistic regression model alone is sufficient to capture the structure of the data. The proposed model has a latent (i.e., factor analysis) model to represent the main technological trends (a.k.a., factors), and adds a sparse component that captures the remaining ad hoc dependence.

- **[Paper link](https://arxiv.org/abs/1912.00524)**: "Latent Factor + Sparse Matrix logistic regression model for network data"

- **Main functions for model selection**
    1. [ADMM_Optim](https://github.com/namjoonsuh/Citation-Network/blob/master/Codes%20%26%20Data/Codes/ADMM_Optim.R) : Main function for making inference for model parameters. Takes adjacency matrix and tuning parameters of models (gamma,delta) as input parameters. Gives the estimated alpha, matrices M, L and S as output of the function.
    2. [Model_Sel](https://github.com/namjoonsuh/Citation-Network/blob/master/Codes%20%26%20Data/Codes/Synthetic%20Networks.R) : Given the adjacency matrix of the network data and the ranges of grids for gamma and delta to search over, the function gives: 
      **(1)** a pair of indices (gamma, delta) that minimizes AIC over the given grid. 
      **(2)** a pair of indices (gamma, delta) that minimizes BIC over the given grid. 
      **(3)** the number of non-zero entries of the estimated S for each point on the grid. 
      **(4)** the rank of the estimated L for each point on the grid.
    3. [CV](https://github.com/namjoonsuh/Citation-Network/blob/master/Codes%20%26%20Data/Codes/Synthetic%20Networks.R) : Code for Network Cross-validation. Refer Section 6.2. of the [paper](https://arxiv.org/abs/1912.00524) for detailed explanation of the procedure. Takes the adjacency matrix of the network data, a pair of tuning parameters (gamma, delta) and the number of K iterations for the averaged mis-classifation rate of edges. Gives the K averaged mis-classification rate as output. 
    4. [Eval_func](https://github.com/namjoonsuh/Citation-Network/blob/master/Codes%20%26%20Data/Codes/Synthetic%20Networks.R) : Code for evaluation of the selected model. Given the adjacency matrix of the network data, and selected model parameters (gamma, delta) through AIC, BIC or Heuristic Network Cross-validation, the function gives:
    **(1)** the rank of estimated L matrix. (i.e. K)
    **(2)** K clustered nodes by applying k-means algorithm on K eigen-vectors of estimated L matrix. 
    **(3)** the number of non-zero entries on upper-triangular part of the estimated S matrix. 
    **(4)** a list of pairs of nodes which create the ad-hoc edges of the selected model. 
    
# Karate club data example
We take a simple example on the application of our model to famous [Zachary's Karate club dataset](https://en.wikipedia.org/wiki/Zachary%27s_karate_club). First we import necessary libraries and functions for the analysis, load the network data, and make the adjacency matrix from the network data. 
```R
##### Load libraries and functions for analysis 
library(igraphdata) # for karate data 
library(igraph)
source('Synthetic Networks.R')
source('ADMM_Optim.R') # delta = 10^-7, r = 15

##### Load the Karate dataset 
data(karate) # type: ?karate to see description 
Karate_ad <- as.matrix(as_adjacency_matrix(karate, type = c("both", "upper", "lower"),
                    attr = NULL, edges = FALSE, names = TRUE,
                    sparse = igraph_opt("sparsematrices")))
```

Over the given grid points with gamma being ranged from 0.012 to 0.0128 with 0.0002 interval and delta being ranged from 0.04 to 0.05 with 0.002 interval, we perform a model selection through Heuristic Network Cross-validation. (There are 30 points in total on the grid.)
First, we run a Model_Sel code for recording the rank of the estimated L and the number of non-zero entries of the estimated S matrices.
Secondly, 

```R
##### Model Selection through HNCV #####
gamma = seq(from=0.012,to=0.0128,by=0.0002);
delta = seq(from=0.04,to=0.05,by=0.002);

Kar_model <- Model_Sel(Karate_ad, gamma, delta);

count <- 1;
MisCl_rate1 <- matrix(rep(0,length(gamma)*length(delta)),nrow=length(gamma),ncol=length(delta));
for(i in 1:length(gamma)){
  for(j in 1:length(delta)){
    MisCl_rate1[i,j] <- CV(Karate_ad,gamma[i],delta[j],10)
    print(count)
    count <- count + 1;
  }
}

CV_ind <- which(MisCl_rate1==min(MisCl_rate1[Kar_model[[4]][1:5,]==2]),arr.ind=TRUE)
```

