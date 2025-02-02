library(latex2exp)
library("plot3D")
source('ADMM_Optim.R')
source('ADMM2_Optim.R') 

library(plyr)
library(ggplot2)

CrtData <- function(alpha,L,S,N){
  # Create empty matrix for storing adjacency matrix X and Probability for 
  X <- matrix(0,N,N); 
  P <- matrix(0,N,N);
  P <- exp(alpha+L+S)/(1+exp(alpha+L+S));
  
  # Create random graph according to (a, L, S)
  for(i in 1:(N-1)){
    for(j in (i+1):N){
      if(P[i,j]>runif(1,0,1))
        X[i,j]<-1
    }
  }
  X <- X + t(X)
  result <- list(X,P)
  return(result)
}

CV <- function(X,gamma,delta,K){
  rate <- 0;
  for(j in 1:K){
    X_fit = X; count = 0;
    n = nrow(X); I_1 = sample(1:n, floor(n/2)); I_2 = setdiff(1:n,I_1);
    M = expand.grid(I_2,I_2);
    for(i in 1:length(I_2)^2){ X_fit[M[i,1],M[i,2]]=0 }
    res = ADMM(X_fit,gamma,delta)
    alpha = res[[1]]; L = res[[3]]; S = res[[4]];
    X_new = CrtData(alpha,L,S,n)[[1]];
    
    for(l in 1:length(I_2)^2){ 
      if(X[M[l,1],M[l,2]]!=X_new[M[l,1],M[l,2]])
        count <- count + 1;
    }
    rate <- rate + (count/length(I_2)^2)/K;
  }
  return(rate)
}

Network1 <- function(N,K,NNZ, case){
  ### Ingredients for creating network : alpha, F, D, S                      
  ### Generate alpha from uniform distribution
  alpha = runif(1,-11,-10)
  ### Create diagonal matrix D with non-negative weights
  D = diag(runif(1,19,20),K)
  ### Create binary matrix F(0,1) whose columns are orthogonal with each other.
  C = floor(N/K);              # C : number of 1s for each column
  F = matrix(0,N,K);           # Create empty F matrix
  if(K>0){
    for(l in 1:K){
      F[((l-1)*C+1):(l*C),l] <- 1
    }
    if(N%%C!=0)
      F[(K*C+1):N,K] <- 1      # In last column of F, we fill the last remaining entries with 1s, 
    # when N is not divided by K.
  }
  if(K==0){
    F <- matrix(0,N,K)
  }
  F = (diag(N)-1/N*matrix(1,N,N))%*%F
  
  ad_hoc_ind = c();  A = choose(K,2);
  for(i in 1:(K-1)){
    for(j in i:(K-1)){
      ind = cbind( sample( ((N/K)*(i-1)+1):((N/K)*i), floor(NNZ/A), replace = FALSE),
                   sample( ((N/K)*(j)+1):((N/K)*(j+1)), floor(NNZ/A), replace = FALSE ) )
      ad_hoc_ind = rbind(ad_hoc_ind,ind)
    }
  }
  
  S = matrix(0,N,N)
  S[ad_hoc_ind]=runif(1,19,20)
  S = S + t(S)
  diag(S) = 0
  
  ### call function to generate the adjacency matrix
  X1 <- as.matrix(SynData(alpha,F,D,S,N))

  ### generate the figure to illustrate the network
  X_draw <- graph_from_adjacency_matrix(X1, mode = c("undirected"))
  
  Edge = which(S>0, arr.ind=TRUE)
  g = graph_from_edgelist(Edge)
  S_g = as.undirected(g)
  
  A=get.edgelist(X_draw)
  B=get.edgelist(S_g)
  
  list = rep(0,length(B[,1]))
  
  for(i in 1:length(B[,1])){
    for(j in 1:length(A[,1])){
      if(B[i,1]==A[j,1] && B[i,2]==A[j,2]){
        list[i] = j;
        break;
      }
    }
  }
  
  E(X_draw)$color <- "red"
  E(X_draw)[list]$color <- "green"
  
  plot(X_draw, family="serif", vertex.size=10, vertex.label=NA)
  title(TeX(sprintf("$\\n = %d, K = %d, |S*| = %d$",N, K, NNZ)),cex.main=1.5,family="Times New Roman")
  
  Res <- list(X1,B,alpha,F%*%D%*%t(F),S)
  return(Res)
}

Network2<-function(N,N_K,N_K_1,K,NNZ, case){
  ### Ingredients for creating network : alpha, F, D, S                      
  ### Generate alpha from random uniform distribution
  alpha = runif(1,-11,-10)
  
  ### Create random symmetric sparse matrix S, 
  ### whose entries are greater than or equal to zero.
  ad_hoc_ind = c();  A = choose(K,2);
  for(i in 1:(K-1)){
    for(j in i:(K-1)){
      ind = cbind( sample( ((N/K)*(i-1)+1):((N/K)*i), floor(NNZ/A), replace = FALSE),
                   sample( ((N/K)*(j)+1):((N/K)*(j+1)), floor(NNZ/A), replace = FALSE ) )
      ad_hoc_ind = rbind(ad_hoc_ind,ind)
    }
  }
  
  S = matrix(0,N,N)
  S[ad_hoc_ind]=runif(1,19,20)
  S = S + t(S)
  diag(S) = 0
  
  ### Create diagonal matrix D with non-negative weights
  D = diag(runif(1,19,20),K)
  
  ### Create binary matrix F(0,1) whose columns are orthogonal with each other.
  C = floor(N/K);              # C : number of 1s for each column
  F = matrix(0,N,K);           # Create empty F matrix
  if(K>0){
    for(l in 1:K){
      F[((l-1)*C+1):(l*C),l] <- 1
    }
    if(N%%C!=0)
      F[(K*C+1):N,K] <- 1      # In last column of F, we fill the last remaining entries with 1s, 
    # when N is not divided by K.
  }
  
  if(N_K_1 != 0){
    TT = sample(setdiff(1:N,ad_hoc_ind),N_K_1,replace=FALSE)
    F[TT,] = 0
    for(i in 1:length(TT)){
      F[TT[i],][c(sample(1:K,2,replace = FALSE))] = 1
    }
  }else{
    TT = 0
  }
  
  RR = sample(setdiff(1:N,c(TT,ad_hoc_ind)), N_K, replace = FALSE) 
  F[RR,] = 1
  
  F = (diag(N)-(1/N)*matrix(1,N,N))%*%F

  # S_Ind = cbind(sample(setdiff(1:N,RR),floor(length(RR)/K),replace=FALSE),
  #              sample(RR,floor(length(RR)/K),replace=FALSE))
  # S[S_Ind] = runif(1,14,15)
  # S = S + t(S)
  # diag(S) = 0
  
  ### call function to generate the adjacency matrix
  X2 <- as.matrix(SynData(alpha,F,D,S,N))
  ### generate the figure to illustrate the network
  X_draw2 <- graph_from_adjacency_matrix(X2, mode = c("undirected"))

  Edge = which(S>0, arr.ind=TRUE)
  g = graph_from_edgelist(Edge)
  S_g = as.undirected(g)
  
  A=get.edgelist(X_draw2)
  B=get.edgelist(S_g)
  
  list = rep(0,length(B[,1]))
  
  for(i in 1:length(B[,1])){
    for(j in 1:length(A[,1])){
      if(B[i,1]==A[j,1] && B[i,2]==A[j,2]){
        list[i] = j;
        break;
      }
    }
  }
  E(X_draw2)$color <- "red"
  E(X_draw2)[list]$color <- "green"
  
  plot(X_draw2, family="serif", vertex.size=10, vertex.label=NA)
  title(sprintf("Case %d",case),family="serif")
  
  output <- list(X2,B,alpha,F%*%D%*%t(F),S,TT,RR)
  return(output)
}

SynData <- function(alpha,F,D,S,N){
  # Create empty matrix for storing adjacency matrix X and Probability for 
  X <- matrix(0,N,N); 
  P <- matrix(0,N,N);
  L <- F%*%D%*%t(F); 
  P <- exp(alpha+L+S)/(1+exp(alpha+L+S));
  
  # Create random graph according to (a, L, S)
  for(i in 1:(N-1)){
    for(j in (i+1):N){
      if(P[i,j]>runif(1,0,1))
        X[i,j]<-1
    }
  }
  X <- X + t(X)

  return(X)
}

Model_Sel <- function(X1,gamma,delta){
  lambda = 1; Count = 1; N = dim(X1)[1];
  AIC <- matrix( 0, nrow=length(gamma),ncol=length(delta) )
  BIC <- matrix( 0, nrow=length(gamma),ncol=length(delta) )
  
  non_zeroS <- matrix( 0, nrow=length(gamma),ncol=length(delta) )
  L_Rank <- matrix( 0, nrow=length(gamma),ncol=length(delta) )
  Like <- matrix( 0, nrow=length(gamma),ncol=length(delta) )
  
  for(g in 1:length(gamma)){
    for(d in 1:length(delta)) {
      ### Use the ADMM method to estimate the parameters ###
      result <- ADMM(X1, gamma[g], delta[d])
      
      a<-result[[1]]
      M<-result[[2]]
      L<-result[[3]]
      S<-result[[4]]
      
      non_zero_S <- 0
      for(i in 1:N){
        for(j in 1:N){
          if(i<j){
            if(S[i,j] != 0)
              non_zero_S = non_zero_S + 1
          }
        }
      }
      
      K<-qr(L)$rank
      M_absolute <- (N*K-((K-1)*K/2)) + non_zero_S + 1
      
      log_sum<-log(1+exp(a + L + S))
      
      log_max <- 0;
      log_max <- a*sum(X1[upper.tri(X1,diag=FALSE)]) +
        (1/2)*sum(X1*(L+S)) - sum(log_sum[upper.tri(log_sum,diag=FALSE)])
      
      AIC[g,d] <- -2*log_max + M_absolute*2
      BIC[g,d] <- -2*log_max + M_absolute*(log((N*(N-1))/2))
      Like[g,d] <- log_max
      non_zeroS[g,d] <- non_zero_S
      L_Rank[g,d] <- qr(L)$rank
      
      print(Count)
      Count <- Count + 1
    }
  }
  
  AIC_index <- which(AIC==min(AIC),arr.ind=TRUE);
  BIC_index <- which(BIC==min(BIC),arr.ind=TRUE);
  
  result <- list(AIC_index,BIC_index,non_zeroS,L_Rank);
  return(result)
}


Model_Sel2 <- function(X1,gamma,delta){
  lambda = 1; Count = 1; N = dim(X1)[1];
  AIC <- matrix( 0, nrow=length(gamma),ncol=length(delta) )
  BIC <- matrix( 0, nrow=length(gamma),ncol=length(delta) )
  
  non_zeroS <- matrix( 0, nrow=length(gamma),ncol=length(delta) )
  L_Rank <- matrix( 0, nrow=length(gamma),ncol=length(delta) )
  Like <- matrix( 0, nrow=length(gamma),ncol=length(delta) )
  
  for(g in 1:length(gamma)){
    for(d in 1:length(delta)) {
      ### Use the ADMM method to estimate the parameters ###
      result <- ADMM2(X1, gamma[g], delta[d])
      
      a<-result[[1]]
      M<-result[[2]]
      L<-result[[3]]
      S<-result[[4]]
      
      non_zero_S <- 0
      for(i in 1:N){
        for(j in 1:N){
          if(i<j){
            if(S[i,j] != 0)
              non_zero_S = non_zero_S + 1
          }
        }
      }
      
      K<-qr(L)$rank
      M_absolute <- (N*K-((K-1)*K/2)) + non_zero_S + 1
      
      log_sum<-log(1+exp(a + L + S))
      
      log_max <- 0;
      log_max <- a*sum(X1[upper.tri(X1,diag=FALSE)]) +
        (1/2)*sum(X1*(L+S)) - sum(log_sum[upper.tri(log_sum,diag=FALSE)])
      
      AIC[g,d] <- -2*log_max + M_absolute*2
      BIC[g,d] <- -2*log_max + M_absolute*(log((N*(N-1))/2))
      Like[g,d] <- log_max
      non_zeroS[g,d] <- non_zero_S
      L_Rank[g,d] <- qr(L)$rank
      
      print(Count)
      Count <- Count + 1
    }
  }
  
  AIC_index <- which(AIC==min(AIC),arr.ind=TRUE);
  BIC_index <- which(BIC==min(BIC),arr.ind=TRUE);
  
  result <- list(AIC_index,BIC_index,non_zeroS,L_Rank);
  return(result)
}


K_means<-function(X, gamma, delta, K_clusters, case){
  result <- ADMM(X, gamma, delta)
  a<-result[[1]]
  M<-result[[2]]
  L<-result[[3]]
  S<-result[[4]]
  
  K = qr(L)$rank
  N = ncol(X)
  FAC = eigen(L)$vectors[,1:K]
  pca <- prcomp(FAC,scale=TRUE)

  if(case==1 | case == 2 | case ==3){
    KMeans = kmeans(FAC, K_clusters, iter.max = 1000, nstart = 100, 
                    algorithm = "Hartigan-Wong")
    
    for(i in 1:K_clusters){
      print(length(which(KMeans$cluster==i,arr.ind=TRUE)))
      print(which(KMeans$cluster==i,arr.ind=TRUE))
    }
    
    plot(FAC[,1], FAC[,2], family="serif", col=KMeans$cluster, cex=1, pch=0, xlab="PC1", ylab="PC2")
    title(sprintf("Case %d",case),family="serif")
  }
  else{
    KMeans = kmeans(cbind(pca$x[,1],pca$x[,2]), K_clusters, iter.max = 1000, nstart = 100, 
                    algorithm = "Hartigan-Wong")
    
    for(i in 1:K_clusters){
      print(length(which(KMeans$cluster==i,arr.ind=TRUE)))
      print(which(KMeans$cluster==i,arr.ind=TRUE))
    }
    
    plot(pca$x[,1], pca$x[,2],family="serif", col=KMeans$cluster, cex=1, pch=0, xlab="PC1", ylab="PC2")
    title(sprintf("Case %d",case),family="serif")
  }
  #scatter3D(eigen(L)$vectors[,1], eigen(L)$vectors[,2], eigen(L)$vectors[,3], theta = 15, phi = 20)
}

Eval_func <- function(Net,gamma,delta,case){
  n = nrow(Net[[1]]);
  Res <- ADMM(Net[[1]],gamma,delta);
  rank <- qr(Res[[3]])$rank;
  K_clusters = rank;
  
  print(rank);
  
  K_means(Net[[1]], gamma, delta, K_clusters, case)
  
  list <- c();
  for(i in 1:n){
    for(j in 1:n){
      if(i<j && Res[[4]][i,j]!=0){
        list = rbind(list, c(i,j));
      }
    }
  }

  count = 0;
  if(length(list)/2==0){
    count = 0;
  }else{
    for(k in 1:(length(list)/2)){
      for(l in 1:(length(Net[[2]])/2)){
        if(list[k,1]==Net[[2]][l,1] && list[k,2]==Net[[2]][l,2])
          count = count + 1;
      }
    }
  }
  print(count);
  print(list);
  print(Net[[2]])
}

getmode <- function(v) {
  uniqv <- unique(v)
  uniqv[which.max(tabulate(match(v, uniqv)))]
}

Intersected_set <- function(d,c){
  f = matrix(0,nrow = length(gamma), ncol = length(delta))
  for(i in 1:length(gamma)){
    for(j in 1:length(delta)){
      if(d[i,j]==1 & c[i,j]==1){
        f[i,j] = 1
      }else{
        f[i,j] = 0
      }
    }
  }
  return(f)
}

plotScree=function(adj,case)
{
  #adj can be symmetric or asymmetric
  m = dim(adj)
  values = eigen(adj %*% t(adj))$values 
  plot(sqrt(values[1:15]), cex=1, pch=22, type="b", 
       lty=2, lwd=3, col="red", bg="red", xlab="", ylab="")
  title(sprintf("Case %d",case))
}


