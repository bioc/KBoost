#' Function to calculate the AUROC and AUPR of a known network.This function was made to test the R implementation of the KBoost Package.
#'
#'@param Net An inferred networks with the predictive probabilities that a transcription factor regulates a gene.
#'@param G_mat A matrix with the gold standard network.
#'@param auto_remove TRUE if the auto-regulation is to be discarded.
#'@param TFs the indexes of the rows of Net that are TFs.
#'@param upper_limit Top number of edges to use. In DREAM5, the authors suggest using the top 100,000 edges only.
#'@export
#'

AUPR_AUROC_matrix=function(Net,G_mat, auto_remove,TFs, upper_limit){

  # Reshape both matrices to facilitate the calculations

  if (auto_remove){

     g_mat = matrix(0,(dim(Net)[1]-1)*(dim(Net)[2]),1)
     net = matrix(0,(dim(Net)[1]-1)*(dim(Net)[2]),1)
     # A counter for indexing the matrices to copy.
     j_o = 1
     j_f = dim(Net)[1]-1
     for (j in 1:dim(Net)[2]){
       g_mat[j_o:j_f,1] = G_mat[-TFs[j],j]
       net[j_o:j_f,1] = Net[-TFs[j],j]
       # update j_o and j_f.
       j_o = j_o + (dim(Net)[1]-1)
       j_f = j_f + (dim(Net)[1]-1)
     }
     Net = net
     G_mat = g_mat

     N = length(Net)

  } else{
    G_mat = matrix(G_mat,dim(Net)[1]*dim(Net)[2],1)

    Net = matrix(Net,dim(Net)[1]*dim(Net)[2],1)

    N = length(Net)

  }

  if (missing(upper_limit)){
    upper_limit_ex =  FALSE
  } else if (upper_limit>N || upper_limit<1){
    stop("upper_limit needs to be lower than the number of edges but larger than 1.")
  } else{
    upper_limit_ex = TRUE
  }


  # Get all of the unique posterior probabilities

 # Post = sort(unique(Net))

  # Initiate the true positives, false positives, true negatives and false negatives

  TP = matrix(0,length(Net),1)

  FP = TP

  TN = TP

  FN = TP

  th = TP

  Prec = TP

  Rec = TP

  FPR = Rec

  AUROC = 0

  AUPR = 0
  # Pre-sort Net and order G_mat accordingly.
  o = order(Net, decreasing = FALSE)

  Net = Net[o]

  G_mat = G_mat[o]

 if (upper_limit_ex){
   Net = Net[1:upper_limit]

   G_mat = G_mat[1:upper_limit]
   N = upper_limit
 }




  # We will use idx as a counter of values of Net, over which edges are accepted as positives.
  idx = 1
  # This variable will count how we store the results of TP, FP,etc.
  i = 0
  # while idx is lower or equal to N. (The length of N)
  while (idx<=N){
    i = i +1
    # Save current value in th.
    th[i] = Net[idx]
    # Now we need to check if values down Net are the same or not.
    # Do a while loop until the values are different.
    idx_next = idx +1
    if (idx!=N){
        while(Net[idx_next]==Net[idx] && idx_next < N){
            idx_next = idx_next +1
        }
    }
    # Cool Now we will count the TP, FP, FN and TN.
    # The condition we are using is Positives: Net<=Net[idx] = 1 and Negatives: Net>Net[idx] = 0.
    TP[i] = sum(G_mat[(idx):N])
    FP[i] = N-(idx-1) - TP[i]
    FN[i] = sum(G_mat[1:(idx-1)])
    TN[i] = ((idx-1)) -FN[i]
    Prec[i] = TP[i]/(TP[i]+FP[i])
    Rec[i] = TP[i]/(TP[i]+FN[i])
    FPR[i] = FP[i]/(TN[i]+FP[i])
    if (i>1){
      # Calculate the Area Under the Curve with the trapezoidal integration rule

      AUPR = AUPR  -(Rec[i] - Rec[i-1])*(Prec[i] + Prec[i-1])/2

      AUROC = AUROC + (Rec[i] + Rec[i-1])*(-FPR[i]+(FPR[i-1]))/2

    }
    idx = idx_next

  }

    Result = list(AUPR=AUPR,AUROC = AUROC, th= th,Prec= Prec,Rec=Rec,FPR=FPR,TP=TP,FP=FP,TN=TN,FN=FN)

    return(Result)

}





