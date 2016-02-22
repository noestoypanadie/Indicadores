//+------------------------------------------------------------------+
//|                                                  Correlation.mq4 |
//|                                                        Cubesteak |
//|                                              cubesteak@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Cubesteak"
#property link      "cubesteak@gmail.com"

//+------------------------------------------------------------------+
//| My function                                                      |
//+------------------------------------------------------------------+

double Correlation (double x[],double y[])
{
int N = ArraySize(x);
double delta_x=0;
double delta_y=0;
double sum_sq_x = 0;
double sum_sq_y = 0;
double sum_coproduct = 0;
double mean_x = x[0];
double mean_y = y[0];
for (int i=0;i<N-1;i++)
   {
    double sweep = (i - 1.0) / i;
    delta_x = (x[i] - mean_x);
    delta_y = (y[i] - mean_y);
    sum_sq_x += delta_x * delta_x * sweep;
    sum_sq_y += delta_y * delta_y * sweep;
    sum_coproduct += delta_x * delta_y * sweep;
    mean_x += (delta_x / i);
    mean_y += (delta_y / i);
   }
double pop_sd_x = MathSqrt( sum_sq_x / N );
double pop_sd_y = MathSqrt( sum_sq_y / N );
double cov_x_y = (sum_coproduct / N);
double correlation = (cov_x_y / (pop_sd_x * pop_sd_y));

return (correlation);
}

//+------------------------------------------------------------------+