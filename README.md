# Subgraph Pattern Mining

The task of finding connectivity patterns in brain networks is formulated as a subgraph pattern mining problem. We treat side information as a label proxy and propose to identify subgraph patterns in the brain that are consistent with the side information and associated with brain injury. In contrast to existing subgraph mining approaches that focus on graph instances alone, the proposed method explores multiple vector-based side views to find an optimal set of subgraph features for graph classification. Based on the side views and some available label information, we design an evaluation criterion for subgraph patterns and derive its lower bound. This allows us to develop a branch-and-bound algorithm to efficiently search for optimal subgraph patterns with pruning, thereby avoiding exhaustive enumeration of all subgraph patterns.

License
-------
© Bokai Cao, 2018. Licensed under an [Apache-2](https://github.com/caobokai/subgraph-pattern-mining/blob/master/LICENSE) license.

Reference
---------
Bokai Cao, Xiangnan Kong, Jingyuan Zhang, Philip S. Yu and Ann B. Ragin. [Mining Brain Networks using Multiple Side Views for Neurological Disorder Identification](https://www.cs.uic.edu/~bcao1/doc/icdm15.pdf). In ICDM 2015.
