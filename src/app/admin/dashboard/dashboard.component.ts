import { Component, OnInit } from '@angular/core';
import { ReportsService } from '../../core/services/reports.service';
import { DashboardStats } from '../../core/models';
import { CommonModule } from '@angular/common';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './dashboard.component.html',
  styleUrl: './dashboard.component.scss'
})
export class DashboardComponent implements OnInit {
  stats: DashboardStats | null = null;
  isLoading: boolean = true;

  constructor(private reportsService: ReportsService) { }

  async ngOnInit() {
    await this.loadStats();
  }

  async loadStats() {
    this.isLoading = true;
    this.stats = await this.reportsService.getDashboardStats();
    this.isLoading = false;
  }

  getTotalWeekHours(): number {
    if (!this.stats) return 0;
    const h = this.stats.week_hours;
    return (
      h.ordinaria_diurna +
      h.ordinaria_nocturna +
      h.extra_diurna +
      h.extra_nocturna +
      h.dominical_festiva_diurna +
      h.dominical_festiva_nocturna
    );
  }
}
